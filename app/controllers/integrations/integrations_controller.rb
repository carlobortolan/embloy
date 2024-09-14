# frozen_string_literal: true

module Integrations
  # IntegrationsController handles Integration-related actions and verifications
  class IntegrationsController < ApplicationController
    include AshbyLambdas
    include ApiExceptionHandler

    def self.submit_form(job, application, application_params, client)
      case job.job_slug.split('__').first
      when 'lever'
        Integrations::Lever::LeverController.post_form(job, application, application_params, client)
      when 'ashby'
        Integrations::Ashby::AshbyController.post_form(job.job_slug.sub('ashby__', ''), application, application_params, client)
      when 'softgarden'
        Integrations::Softgarden::SoftgardenController.post_form(job.job_slug.sub('softgarden__', ''), application, application_params, client)
      end
    end

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

    def self.fetch_token(client, issuer, token_type)
      # Find API Key for current client
      current_keys = client.tokens.where(token_type:, issuer:).where('expires_at > ?', Time.now.utc)
      return if current_keys.empty?

      current_keys.detect(&:active?)&.token
    end

    def self.fetch_token!(client, issuer, token_type)
      # Find API Key for current client and throw errors if missing or inactive
      current_keys = client.tokens.where(token_type:, issuer:).where('expires_at > ?', Time.now.utc)
      raise CustomExceptions::InvalidInput::Quicklink::ApiKey::Missing and return if current_keys.empty?

      api_key = current_keys.detect(&:active?)&.token
      raise CustomExceptions::InvalidInput::Quicklink::ApiKey::Inactive and return if api_key.nil?

      api_key
    end

    def self.save_token(client, name, issuer, token_type, token, expires_at, issued_at) # rubocop:disable Metrics/ParameterLists
      # Find API Key for current client
      client.tokens.where(token_type:, issuer:).where('expires_at > ?', Time.now.utc).each(&:deactivate!)
      client.tokens.create!(token_type:, name:, issuer:, token:, expires_at:, issued_at:)
    end

    def self.handle_internal_job(client, parsed_job)
      return unless parsed_job.is_a?(Hash)

      job_slug = parsed_job['job_slug']
      return if job_slug.nil?

      if client.jobs.find_by(job_slug: parsed_job['job_slug']).nil?
        # Create new job if not already in the database
        create_internal_job(client, parsed_job)
      else
        # Update existing job
        update_existing_job(client, parsed_job)
      end
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

    def self.create_internal_job(client, parsed_job)
      job = Job.new(parsed_job)
      job.save!
      job.user = client
      client.jobs << job
      job
    end

    def self.update_existing_job(client, parsed_job)
      job = client.jobs.find_by(job_slug: parsed_job['job_slug'])

      # Delete application options that are not in the current version of the job
      ext_ids = parsed_job['application_options_attributes'].map { |option| option['ext_id'] }
      job.application_options.where.not(ext_id: ext_ids).destroy_all

      # Update or create application options depending on whether they already exist (aka ext_id is taken)
      parsed_job['application_options_attributes'].each do |option|
        application_option = job.application_options.find_or_initialize_by(ext_id: option['ext_id'])
        application_option.update!(option)
      end
      job
    end
  end
end
