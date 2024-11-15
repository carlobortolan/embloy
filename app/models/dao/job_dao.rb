# frozen_string_literal: true

# job_dao.rb
module Dao
  # The JobDao class is responsible for defining the serialization rules for a Job object. This includes specifying which attributes should be included in the serialized output.
  module JobDao
    extend ActiveSupport::Concern

    def dao(include_image: false, include_employer: false, include_description: false, include_applications: false, include_application_options: false, include_application_answers: false) # rubocop:disable Metrics/AbcSize,Metrics/ParameterLists
      job = {}
      job[:job] = {
        id: id,
        title: title,
        position: position,
        job_type: job_type,
        job_slug: job_slug,
        job_status: job_status,
        referrer_url: referrer_url,
        salary: salary,
        currency: currency,
        start_slot: start_slot,
        duration: duration,
        code_lang: code_lang,
        longitude: longitude,
        latitude: latitude,
        country_code: country_code,
        postal_code: postal_code,
        city: city,
        address: address,
        view_count: view_count,
        applications_count: applications_count,
        created_at: created_at,
        updated_at: updated_at
      }
      job[:job][:image_url] = image_url.url if include_image
      job[:job][:description] = description if include_description
      job[:job][:employer] = add_employer_details if include_employer
      job[:job][:application_options] = application_options if include_application_options
      job[:job][:application_answers] = application_answers if include_application_answers
      job[:job][:applications] = applications if include_applications
      job
    end

    def add_employer_details # rubocop:disable Metrics/AbcSize
      res_hash = {}
      if user.company?
        res_hash['employer_email'] = user.company_email
        res_hash['employer_name'] = user.company_name
        res_hash['employer_phone'] = user.company_phone
        res_hash['employer_image_url'] = user.company_logo&.url || ''
      else
        res_hash['employer_email'] = user.email
        res_hash['employer_name'] = "#{user.first_name} #{user.last_name}"
        res_hash['employer_phone'] = user.phone
        res_hash['employer_image_url'] = user.image_url&.url || ''
      end

      res_hash
    end
  end
end
