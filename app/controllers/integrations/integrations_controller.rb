# frozen_string_literal: true

module Integrations
  # IntegrationsController handles Integration-related actions and verifications
  class IntegrationsController < ApplicationController
    include AshbyLambdas
    include ApiExceptionHandler

    def self.submit_form(job, application, application_params, client, session)
      case job&.job_slug&.split('__')&.first
      when 'lever'
        Integrations::Lever::LeverController.post_form(job, application, application_params, client, session) if session
      when 'ashby'
        Integrations::Ashby::AshbyController.post_form(job.job_slug.sub('ashby__', ''), application, application_params, client)
      when 'softgarden'
        Integrations::Softgarden::SoftgardenController.post_form(job.job_slug.sub('softgarden__', ''), application, application_params, client)
      end
    end

    # Deprecated method used for fetching job postings on every application - now handled by the sync_postings method
    def self.get_posting(mode, job_slug, client, job)
      case mode
      when 'lever'
        Integrations::Lever::LeverController.fetch_posting(job_slug.sub('lever__', ''), client, job)
      when 'ashby'
        Integrations::Ashby::AshbyController.fetch_posting(job_slug.sub('ashby__', ''), client, job)
      when 'softgarden'
        Integrations::Softgarden::SoftgardenController.fetch_posting(job_slug.sub('softgarden__', ''), client, job)
      end
    end

    def self.sync_postings(client, jobs)
      case mode
      when 'lever'
        Integrations::Lever::LeverController.synchronize(client, jobs)
      when 'ashby'
        Integrations::Ashby::AshbyController.synchronize(client, jobs)
      when 'softgarden'
        Integrations::Softgarden::SoftgardenController.synchronize(client, jobs)
      end
    end

    # Deprecated method used for fetching job postings on every application - now handled by the sync_postings method
    def self.handle_internal_job(client, parsed_job)
      return unless parsed_job.is_a?(Hash)

      job_slug = parsed_job['job_slug']
      return if job_slug.nil?

      existing_job = client.jobs.find_by(job_slug:)
      existing_job.nil? ? create_internal_job(client, parsed_job) : update_existing_job(existing_job, parsed_job)
    end

    def self.handle_application_response(response)
      Rails.logger.debug("Response: #{response.inspect}")
      case response
      when Net::HTTPSuccess
        Rails.logger.debug("Application submitted successfully: #{response.body}")
      when Net::HTTPBadRequest
        raise CustomExceptions::InvalidInput::Quicklink::Application::Malformed and return
      when Net::HTTPUnauthorized
        raise CustomExceptions::InvalidInput::Quicklink::Application::Unauthorized and return
      when Net::HTTPUnprocessableEntity || Net::HTTPConflict
        raise CustomExceptions::InvalidInput::Quicklink::Application::Duplicate and return
      end
    end

    def self.handle_internal_jobs(client, parsed_jobs)
      return if parsed_jobs.empty?

      job_slugs = parsed_jobs.map { |job| job['job_slug'] }
      existing_jobs = client.jobs.includes(:rich_text_description, :image_url_attachment, :application_options, :pg_search_document).where(job_slug: job_slugs).index_by(&:job_slug)

      parsed_jobs.each do |parsed_job|
        existing_job = existing_jobs[parsed_job['job_slug']]
        if existing_job
          update_existing_job(existing_job, parsed_job)
        else
          create_internal_job(client, parsed_job)
        end
      end
    end

    def self.create_internal_job(client, parsed_job)
      job = client.jobs.create!(parsed_job.except('application_options_attributes'))
      upsert_application_options(job, parsed_job['application_options_attributes'])
      job
    end

    def self.update_existing_job(job, parsed_job)
      job.update!(parsed_job.except('application_options_attributes'))
      upsert_application_options(job, parsed_job['application_options_attributes'])
      job
    end

    def self.upsert_application_options(job, application_options_attributes) # rubocop:disable Metrics/PerceivedComplexity,Metrics/CyclomaticComplexity
      return if application_options_attributes.nil? || application_options_attributes.empty?

      # Collect ext_ids from application_options_attributes
      ext_ids = application_options_attributes.map { |option| option['ext_id'] }

      # Delete application options that are not in the current version of the job
      job.application_options.where.not(ext_id: ext_ids).destroy_all

      # Define the keys that should be present in each option
      required_keys = %w[job_id ext_id question question_type required options created_at updated_at]

      # Prepare attributes for upsert, ensuring all keys are present
      application_options_attributes = application_options_attributes.map do |option|
        option_with_defaults = {
          'job_id' => job.id,
          'ext_id' => option['ext_id'],
          'question' => option['question'],
          'question_type' => option['question_type'] || 'yes_no',
          'required' => option['required'] ? 'true' : 'false',
          'options' => option['options'].blank? && option['question_type'] == 'file' ? ['pdf'] : option['options'],
          'created_at' => Time.current,
          'updated_at' => Time.current
        }

        Rails.logger.debug("Option with defaults: #{option_with_defaults.inspect}")

        # Ensure all required keys are present
        required_keys.each do |key|
          option_with_defaults[key] ||= nil
        end

        option_with_defaults
      end

      # TODO: Decide whether to enable validation of new entries before upserting
      # application_options_attributes.each do |attributes|
      #  errors = ApplicationOption.validate(attributes)
      #  next if errors.empty?
      #
      #  Rails.logger.debug("Invalid Option: #{attributes.inspect}")
      #  Rails.logger.debug("Validation Errors: #{errors.full_messages.join(', ')}")
      #  raise ActiveRecord::RecordInvalid.new(ApplicationOption.new), "Invalid application option: #{errors.full_messages.join(', ')}"
      # end

      # Perform upsert to create or update application options in a single batch
      ApplicationOption.upsert_all(application_options_attributes, unique_by: %i[job_id ext_id])
    end
  end
end
