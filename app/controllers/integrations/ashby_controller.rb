# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'
require 'base64'
require 'dotenv'

Dotenv.load('.env')

module Integrations
  # LeverController handles oauth-related actions
  class AshbyController < IntegrationsController
    ASHBY_POST_FORM_URL = 'https://api.ashbyhq.com'
    def self.submit_form(_posting_id, _client, _application_details)
      # TODO: https://developers.ashbyhq.com/reference/applicationformsubmit

      #       application_details << {"path":"_systemfield_name","value":client.name_first + " " + client.name_last}
      #       application_details << {"path":"_systemfield_email","value":client.email}
      #       application_details << {"path":"_systemfield_resume","value":"resume_1"}
      puts 'STARTING TO SEND TO ASHBY'
      url = URI('https://api.ashbyhq.com/applicationForm.submit')

      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true

      request = Net::HTTP::Post.new(url)
      request['Accept'] = 'application/json'
      # TODO: ASHBY_API_KEY needs to be replaced with client's own Embloy-ASHBY_API_KEY (e.g., client.integrations.ashby_api_key)
      # request['authorization'] = "Basic #{Base64.strict_encode64("94befa3e484fbfa12ae6929f81c9b289ec37e3a6072473c6dbdf2992eb6c5ccf" + ':')}"
      request['authorization'] = 'Basic OTRiZWZhM2U0ODRmYmZhMTJhZTY5MjlmODFjOWIyODllYzM3ZTNhNjA3MjQ3M2M2ZGJkZjI5OTJlYjZjNWNjZjo='
      request['content-type'] = 'multipart/form-data'
      request.body = '{"jobPostingId":"a6a6b95e-17ae-45f7-a5b0-c46a871b4c7e"}'

      response = http.request(request)
      # TODO: Handle response
      puts response.read_body
    end

    # rubocop:disable all
    def self.get_posting(posting_id, client, job)
      # TODO: https://developers.ashbyhq.com/reference/jobpostinginfo

      # Find API Key for current client
      current_keys = client.tokens.where(token_type: 'api_key', issuer: 'ashby').where('expires_at > ?', Time.now.utc)
      raise CustomExceptions::InvalidInput::Quicklink::ApiKey::Missing and return if current_keys.empty?

      api_key = current_keys.detect(&:active?)&.token
      raise CustomExceptions::InvalidInput::Quicklink::ApiKey::Inactive and return if api_key.nil?

      # Build request
      url = URI('https://api.ashbyhq.com/jobPosting.info')
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true
      request = Net::HTTP::Post.new(url)
      request['accept'] = 'application/json'
      request['content-type'] = 'application/json'
      request['authorization'] = "Basic #{api_key}"
      request.body = "{\"jobPostingId\":\"#{posting_id}\"}"

      # Make request to Ashby API
      response = http.request(request)
      case response
      when Net::HTTPSuccess
        job = JobParser.parse(JSON.parse(File.read('app/controllers/integrations/ashby_config.json')), JSON.parse(response.body), AshbyLambdas)
        job['job_slug'] = "ashby__#{job['job_slug']}"
        job['user_id'] = client.id.to_i
        job = job.to_active_record!(job)
        # TODO: uncomment to activate new parser
        # parse_json(JSON.parse(File.read('app/controllers/integrations/ashby_config_new.json')),JSON.parse(response.body))
      when Net::HTTPBadRequest
        raise CustomExceptions::InvalidInput::Quicklink::Request::Malformed and return
      when Net::HTTPUnauthorized
        raise CustomExceptions::InvalidInput::Quicklink::ApiKey::Unauthorized and return
      end

      if client.jobs.find_by(job_slug: job['job_slug']).nil?
        # Build new job
        job = Job.new(job)
        job.save!
        job.user = client
        client.jobs << job
      else
        # Update existing job
        # client.jobs.find_by(job_slug: job['job_slug']).update!(job)

        job_record = client.jobs.find_by(job_slug: job['job_slug'])
        puts "Job = #{job}"

        # Delete application options that are not in the current version of the job
        ext_ids = job['application_options_attributes'].map { |option| option['ext_id'] }
        job_record.application_options.where.not(ext_id: ext_ids).destroy_all

        # Update or create application options depending on whether they already exist (aka ext_id is taken)
        job['application_options_attributes'].each do |option|
          puts "Starting with !!! = #{option['ext_id']}"
          # uuid = option['ext_id'][/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/]
          application_option = job_record.application_options.find_or_initialize_by(ext_id: option['ext_id'])
          puts "Found Option ??? = #{application_option.ext_id}"
          # option['ext_id'] = uuid
          application_option.update!(option)
        end

        return client.jobs.find_by(job_slug: job['job_slug'])
      end
      job
    end

    def self.parse_json(origin, destination)
      begin

        url = URI("http://localhost:8080/parse/json/json")
        http = Net::HTTP.new(url.host, url.port)
        http.use_ssl = false
        request = Net::HTTP::Post.new(url)
        request["accept"] = 'application/json'
        request["content-type"] = 'application/json'
        request.basic_auth 'ps', 'pw'
        request.body = {"origin": origin, "destination": destination}.to_json

        response = http.request(request)
        puts "RESPONSE: #{response.read_body}"
      rescue => e
      end

    end


    # rubocop:enable Metrics/AbcSize
  end
end
