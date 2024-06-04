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

    # rubocop:disable Metrics/AbcSize
    def self.get_posting(_posting_id, client, job)
      # TODO: https://developers.ashbyhq.com/reference/jobpostinginfo

      # TODO: REMOVE AND MAKE DEPENDANT ONA USERS ASHBY KEY
      url = URI('https://api.ashbyhq.com/jobPosting.info')

      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true

      request = Net::HTTP::Post.new(url)
      request['accept'] = 'application/json'
      request['content-type'] = 'application/json'
      request['authorization'] = 'Basic OTRiZWZhM2U0ODRmYmZhMTJhZTY5MjlmODFjOWIyODllYzM3ZTNhNjA3MjQ3M2M2ZGJkZjI5OTJlYjZjNWNjZjo='
      request.body = '{"jobPostingId":"a6a6b95e-17ae-45f7-a5b0-c46a871b4c7e"}'

      response = http.request(request)
      case response # TODO: Handle errors
      when Net::HTTPSuccess
        job = JobParser.parse(JSON.parse(File.read('app/controllers/integrations/ashby_config.json')), JSON.parse(response.body), AshbyLambdas)
        job['job_slug'] = "ashby__#{job['job_slug']}"
        job['user_id'] = client.id.to_i
        job = job.to_active_record!(job)
        parse_json(JSON.parse(File.read('app/controllers/integrations/ashby_config_new.json')),JSON.parse(response.body))
      end

      if client.jobs.find_by(job_slug: job['job_slug']).nil?
        job = Job.new(job)
        job.save!
        job.user = client
        client.jobs << job
      else
        client.jobs.find_by(job_slug: job['job_slug']).update!(job)
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
