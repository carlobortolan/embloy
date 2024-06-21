# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'
require 'base64'
require 'mawsitsit'

module Integrations
  # AshbyController handles Ashby-related actions
  class AshbyController < IntegrationsController
    ASHBY_POST_FORM_URL = 'https://api.ashbyhq.com/applicationForm.submit'
    ASHBY_FETCH_POSTING_URL = 'https://api.ashbyhq.com/jobPosting.info'

    # Reference: https://developers.ashbyhq.com/reference/applicationformsubmit
    def self.post_form(_posting_id, application, client)
      # Build request
      url = URI(ASHBY_POST_FORM_URL)
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true
      request = Net::HTTP::Post.new(url)
      request['accept'] = 'application/json'
      request['content-type'] = 'multipart/form-data'
      request['authorization'] = "Basic #{fetch_token(client, 'ashby', 'api_key')}"

      # TODO: @jh Parse application answers using new parser gem
      request.body = application.application_answers.to_json

      # Make request to Ashby API
      response = http.request(request)
      handle_application_response(response)
    end

    # rubocop:disable Metrics/AbcSize
    # Reference: https://developers.ashbyhq.com/reference/jobpostinginfo
    def self.fetch_posting(posting_id, client, job)
      # Build request
      url = URI(ASHBY_FETCH_POSTING_URL)
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true
      request = Net::HTTP::Post.new(url)
      request['accept'] = 'application/json'
      request['content-type'] = 'application/json'
      request['authorization'] = "Basic #{fetch_token(client, 'ashby', 'api_key')}"
      request.body = "{\"jobPostingId\":\"#{posting_id}\"}"

      # Make request to Ashby API
      response = http.request(request)
      case response
      when Net::HTTPSuccess
        config = JSON.parse(File.read('app/controllers/integrations/ashby_config.json'))
        resp = JSON.parse(response.body)
        job = Mawsitsit.parse(resp, config, true)
        job['job_slug'] = "ashby__#{job['job_slug']}"
        job['user_id'] = client.id.to_i
        handle_internal_job(client, job)
      when Net::HTTPBadRequest
        raise CustomExceptions::InvalidInput::Quicklink::Request::Malformed and return
      when Net::HTTPUnauthorized
        raise CustomExceptions::InvalidInput::Quicklink::ApiKey::Unauthorized and return
      end
    end
    # rubocop:enable Metrics/AbcSize
  end
end
