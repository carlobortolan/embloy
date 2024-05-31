# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'
require 'base64'
require 'dotenv'

Dotenv.load(".env")

module Integrations
  # LeverController handles oauth-related actions
  class AshbyController < IntegrationsController
    ASHBY_POST_FORM_URL = 'https://api.ashbyhq.com'

    def register
      # Save Ashby API-key (sent using basic auth) to current user
    end

    def self.submit_form(_posting_id, application_details)
      # TODO: https://developers.ashbyhq.com/reference/applicationformsubmit
      puts 'STARTING TO SEND TO ASHBY'
      url = URI('https://api.ashbyhq.com/applicationForm.submit')

      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true

      request = Net::HTTP::Post.new(url)
      request['Accept'] = 'application/json'
      # TODO: ASHBY_API_KEY needs to be replaced with client's own Embloy-ASHBY_API_KEY (e.g., client.integrations.ashby_api_key)
      #request['authorization'] = "Basic #{Base64.strict_encode64("94befa3e484fbfa12ae6929f81c9b289ec37e3a6072473c6dbdf2992eb6c5ccf" + ':')}"
      request["authorization"] = 'Basic OTRiZWZhM2U0ODRmYmZhMTJhZTY5MjlmODFjOWIyODllYzM3ZTNhNjA3MjQ3M2M2ZGJkZjI5OTJlYjZjNWNjZjo='
      request['content-type'] = 'multipart/form-data'
      request.body = "{\"jobPostingId\":\"a6a6b95e-17ae-45f7-a5b0-c46a871b4c7e\"}"

      response = http.request(request)
      # TODO: Handle response
      puts response.read_body
    end

    def self.get_posting(posting_id, client, job)
      # TODO: https://developers.ashbyhq.com/reference/jobpostinginfo

      # TODO: REMOVE AND MAKE DEPENDANT ONA USERS ASHBY KEY
      url = URI("https://api.ashbyhq.com/jobPosting.info")

      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true

      request = Net::HTTP::Post.new(url)
      request["accept"] = 'application/json'
      request["content-type"] = 'application/json'
      request["authorization"] = 'Basic OTRiZWZhM2U0ODRmYmZhMTJhZTY5MjlmODFjOWIyODllYzM3ZTNhNjA3MjQ3M2M2ZGJkZjI5OTJlYjZjNWNjZjo='
      request.body = "{\"jobPostingId\":\"a6a6b95e-17ae-45f7-a5b0-c46a871b4c7e\"}"

      response = http.request(request)
      case response # TODO: Handle errors
      when Net::HTTPSuccess
        job = JobParser.parse(JSON.parse(File.read('app/controllers/integrations/ashby_config.json')), JSON.parse(response.body))
        job["job_slug"] = "ashby__#{job["job_slug"]}"
        job = job.to_active_record
      else
        nil
      end

      unless client.jobs.find_by(job_slug: job['job_slug']).nil?

        return client.jobs.find_by(job_slug: job['job_slug'])

      else
        job = Job.new(job_slug: "ashby__#{posting_id}", user_id: client.id.to_i)
        job.save!
        job.user = client
        client.jobs << job
        client.jobs << job
        #job.update!(title: 'test')
      end
      job
    end

    def self.get_questions(posting_id, client, job)
      # TODO: https://developers.ashbyhq.com/reference/applicationinfo
    end
  end
end
