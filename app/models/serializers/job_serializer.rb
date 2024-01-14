# frozen_string_literal: true

require 'fog/backblaze'

# job_serializer.rb
module Serializers
  # The JobSerializer class is responsible for defining the serialization
  # rules for a Job object. This includes specifying which attributes
  # should be included in the serialized output.
  class JobSerializer
    # Creates a externally managed job with placeholder fields
    def self.create_emj(job_slug, user_id)
      job = Job.create!(
        user_id:,
        title: job_slug,
        # TODO: Save referrer URL
        description: 'HERE IS THE URL OF THE REFERRER',
        longitude: '0.0',
        latitude: '0.0',
        position: 'EMJ',
        salary: '1',
        start_slot: Time.now,
        key_skills: 'EMJ',
        duration: '1',
        currency: '0',
        job_type: 'EMJ',
        job_type_value: '1'
      )
      puts 'Created new job for'
      job
    end

    # Current approach; - TODO: @cb find easier way to serialize job JSONs & remove commented code when switching to S3
    def self.json_for(job)
      return if job.nil?

      begin
        unless job.image_url.url.nil?
          # use custom url
          # Parse the JSON to a hash
          res_hash = JSON.parse(job.to_json(except: [:image_url]))
          # Add the 'image_url' field with the value 'job.image_url.url'
          res_hash['image_url'] = job.image_url.url
          return res_hash.to_json
        end
      rescue Fog::Errors::Error
        # do nothing & continue with default url
      end
      # use default url
      res_hash = JSON.parse(job.to_json(except: [:image_url]))
      res_hash['image_url'] = 'https://embloy.onrender.com/assets/img/features_3.png'
      res_hash.to_json
    end

    def self.get_json_include_user(job)
      return if job.nil?

      res_hash = job_to_hash(job)
      add_image_url(job, res_hash)
      add_employer_details(job, res_hash)

      res_hash.to_json
    end

    def self.jsons_for(jobs)
      res_json = []

      jobs.each do |job|
        json = Job.json_for(job)
        res_json << json unless json.nil? || json.empty?
      end
      res_json.join(',')
    end

    def self.get_jsons_include_user(jobs)
      res_json = []
      return if jobs.nil?

      jobs.each do |job|
        json = Job.get_json_include_user(job)
        res_json << json unless json.nil? || json.empty?
      end
      res_json.join(',')
    end

    def self.job_to_hash(job)
      JSON.parse(job.to_json(except: [:image_url]))
    end

    def self.add_image_url(job, res_hash)
      res_hash['image_url'] = if job.image_url&.url
                                job.image_url.url
                              else
                                ''
                              end
    end

    def self.add_employer_details(job, res_hash)
      res_hash['employer_email'] = job.user.email
      res_hash['employer_name'] = "#{job.user.first_name} + #{job.user.first_name}"
      res_hash['employer_phone'] = job.user.phone
    end
  end
end
