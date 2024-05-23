# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'

module Integrations
  # LeverController handles oauth-related actions
  class LeverController < IntegrationsController
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
      request['Authorization'] = "Basic #{Base64.strict_encode64(ENV.fetch('ASHBY_API_KEY', ''))}"
      request['content-type'] = 'multipart/form-data'
      request.body = application_details

      response = http.request(request)
      # TODO: Handle response
      puts response.read_body
    end

    def self.get_posting(posting_id, client, job)
      # TODO: https://developers.ashbyhq.com/reference/jobinfo

      if job.nil?
        job = Job.new(job_slug: "ashby__#{posting_id}", user_id: client.id.to_i)
        job.save!
        job.user = client
        client.jobs << job
      else
        job.update!(title: 'test')
      end
      job
    end

    def self.get_questions(posting_id, client, job)
      # TODO: https://developers.ashbyhq.com/reference/applicationinfo
    end
  end
end
