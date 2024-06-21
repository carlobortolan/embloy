# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'
require 'jwt'

module Integrations
  # LeverController handles internal actions used by an Embloy SDK or API controller
  class LeverController < IntegrationsController
    LEVER_POST_FORM_URL = 'https://api.sandbox.lever.co/v1/postings/postingId/apply?send_confirmation_email=true'
    LEVER_FETCH_POSTING_URL = 'https://api.sandbox.lever.co/v1/postings/postingId'
    LEVER_FETCH_QUESTIONS_URL = 'https://api.sandbox.lever.co/v1/postings/postingId/applicationQuestions'

    # Posts application form to Lever API
    # Reference: https://hire.sandbox.lever.co/developer/documentation#apply-to-a-posting
    def self.post_form(posting_id, application, client)
      # Build request
      url = URI(LEVER_POST_FORM_URL.gsub('postingId', posting_id))
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true
      request = Net::HTTP::Post.new(url)
      request['accept'] = 'application/json'
      request['content-type'] = 'application/json'
      request['authorization'] = "Basic #{validate_token(client)}"

      # TODO: @jh Parse application answers using new parser gem
      request.body = application.application_answers.to_json

      # Make request to Lever API
      response = http.request(request)
      handle_application_response(response)
    end

    # NOTE: LEVER_FETCH_POSTING_URL only returns the job; for the job options, use LEVER_GET_QUESTIONS_URL (see get_questions)
    # rubocop:disable Metrics/AbcSize
    # Reference: https://hire.sandbox.lever.co/developer/documentation#retrieve-a-single-posting
    def self.fetch_posting(posting_id, client, job)
      # Build request
      url = URI(LEVER_FETCH_POSTING_URL.gsub('postingId', posting_id))
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true
      request = Net::HTTP::Post.new(url)
      request['accept'] = 'application/json'
      request['content-type'] = 'application/json'
      request['authorization'] = "Basic #{validate_token(client)}"

      # Make request to Lever API
      response = http.request(request)
      case response
      when Net::HTTPSuccess
        # >>> TODO: @jh Parse job using new parser gem
        job = JobParser.parse(JSON.parse(File.read('app/controllers/integrations/lever_config.json')), JSON.parse(response.body), AshbyLambdas)
        job['job_slug'] = "lever__#{job['job_slug']}"
        job['user_id'] = client.id.to_i
        job = job.to_active_record!(job)
        # <<< TODO: @jh Parse job

        # Save or update job in database
        handle_internal_job(client, job)
      when Net::HTTPBadRequest
        raise CustomExceptions::InvalidInput::Quicklink::Request::Malformed and return
      when Net::HTTPUnauthorized
        raise CustomExceptions::InvalidInput::Quicklink::ApiKey::Unauthorized and return
      end

      handle_internal_job(client, job)
    end

    # Returns the application questions for a specific job posting
    # Reference: https://hire.sandbox.lever.co/developer/documentation#retrieve-posting-application-questions
    def self.get_questions(posting_id, client, job)
      # Build request
      url = URI(LEVER_FETCH_QUESTIONS_URL.gsub('postingId', posting_id))
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true
      request = Net::HTTP::Post.new(url)
      request['accept'] = 'application/json'
      request['content-type'] = 'application/json'
      request['authorization'] = "Basic #{validate_token(client)}"

      # Make request to Lever API
      response = http.request(request)
      case response
      when Net::HTTPSuccess
        # TODO: @jh Parse job
        job = JobParser.parse(JSON.parse(File.read('app/controllers/integrations/lever_config.json')), JSON.parse(response.body), AshbyLambdas)
        job['job_slug'] = "lever__#{job['job_slug']}"
        job['user_id'] = client.id.to_i
        job = job.to_active_record!(job)

        # Save or update job in database
        handle_internal_job(client, job)
      when Net::HTTPBadRequest
        raise CustomExceptions::InvalidInput::Quicklink::Request::Malformed and return
      when Net::HTTPUnauthorized
        raise CustomExceptions::InvalidInput::Quicklink::ApiKey::Unauthorized and return
      end
    end
    # rubocop:enable Metrics/AbcSize

    private

    # Check if the Lever access token is valid, otherwise use Lever refresh token to get a new one
    def validate_token(client)
      access_token = fetch_token(client, 'lever', 'access_token')

      if access_token.nil?
        refresh_token = fetch_token!(client, 'lever', 'refresh_token')
        access_token = lever_access_token(refresh_token)
      end

      access_token
    end

    # Retrieve a new access token using the refresh token (step 5)
    def lever_access_token(refresh_token)
      uri = URI.parse(LeverOauthController::LEVER_ACCESS_TOKEN_URL)
      request = Net::HTTP::Post.new(uri)
      request.content_type = 'application/x-www-form-urlencoded'
      request.body = URI.encode_www_form({
                                           'grant_type' => 'refresh_token',
                                           'client_id' => ENV.fetch('LEVER_CLIENT_ID', nil),
                                           'client_secret' => ENV.fetch('LEVER_CLIENT_SECRET', nil),
                                           'refresh_token' => refresh_token
                                         })

      req_options = {
        use_ssl: uri.scheme == 'https'
      }

      response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
        http.request(request)
      end

      # Extract the new access token from the response and return it
      JSON.parse(response.body)['access_token']
    end
  end
end
