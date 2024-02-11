# frozen_string_literal: true

require 'fog/backblaze'

# job_serializer.rb
module Serializers
  # The JobSerializer class is responsible for defining the serialization
  # rules for a Job object. This includes specifying which attributes
  # should be included in the serialized output.
  class JobSerializer
    # Current approach; - TODO: @cb find easier way to serialize job JSONs & remove commented code when switching to S3
    def self.json_for(job)
      return if job.nil?

      begin
        unless job.image_url.url.nil?
          # use custom url
          # Parse the JSON to a hash
          res_hash = JSON.parse(job.to_json(include: :application_options, except: [:image_url]))
          # Add the 'image_url' field with the value 'job.image_url.url'
          res_hash['image_url'] = job.image_url.url
          return res_hash.to_json
        end
      rescue Fog::Errors::Error
        # do nothing & continue with default url
      end
      # use default url
      res_hash = JSON.parse(job.to_json(include: :application_options, except: [:image_url]))
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

    def self.get_json_include_user_exclude_image(job)
      return if job.nil?

      res_hash = job_to_hash(job)
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
      JSON.parse(job.to_json(include: :application_options, except: [:image_url]))
    end

    def self.add_image_url(job, res_hash)
      res_hash['image_url'] = job.image_url&.url || ''
    end

    def self.add_employer_details(job, res_hash)
      user = job.user
      res_hash['employer_email'] = user.email
      res_hash['employer_name'] = "#{user.first_name} #{user.last_name}"
      res_hash['employer_phone'] = user.phone
      res_hash['employer_image_url'] = user.image_url&.url || ''
    end
  end
end
