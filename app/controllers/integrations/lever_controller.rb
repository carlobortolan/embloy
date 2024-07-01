# frozen_string_literal: true

require 'net/http'
require 'net/http/post/multipart'
require 'uri'
require 'json'
require 'jwt'

module Integrations
  # LeverController handles internal actions used by an Embloy SDK or API controller
  class LeverController < IntegrationsController
    LEVER_POST_FORM_URL = 'https://api.sandbox.lever.co/v1/postings/postingId/apply?send_confirmation_email=true'
    LEVER_POST_FILE_URL = 'https://api.sandbox.lever.co/v1/uploads'
    LEVER_FETCH_POSTING_URL = 'https://api.sandbox.lever.co/v1/postings/postingId'
    LEVER_FETCH_QUESTIONS_URL = 'https://api.sandbox.lever.co/v1/postings/postingId/apply'

    # Posts application form to Lever API
    # Reference: https://hire.sandbox.lever.co/developer/documentation#apply-to-a-posting
    def self.post_form(posting_id, application, application_params, client)
      handle_lever_file_uploads(application, application_params, client)

      # Build and send request
      url = URI(LEVER_POST_FORM_URL.gsub('postingId', posting_id))
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true
      request = Net::HTTP::Post.new(url)
      request['accept'] = 'application/json'
      request['content-type'] = 'application/json'
      request['authorization'] = "Bearer #{validate_token(client)}"
      request.body = build_request_body(application)

      response = http.request(request)

      # Handle response
      handle_application_response(response)
    end

    # Handles file uploads for Lever
    def self.handle_lever_file_uploads(application, application_params, client) # rubocop:disable Metrics/AbcSize
      application_params[:application_answers].each_value do |param|
        next unless param[:file].present?

        url = URI(LEVER_POST_FILE_URL)
        File.open(param[:file].tempfile.path) do |file|
          request = Net::HTTP::Post::Multipart.new(
            url.path,
            'file' => UploadIO.new(file, param[:file].content_type, param[:file].original_filename)
          )
          http = Net::HTTP.new(url.host, url.port)
          http.use_ssl = true
          request['Authorization'] = "Bearer #{validate_token(client)}"

          response = http.request(request)
          if response.is_a?(Net::HTTPSuccess)
            data = JSON.parse(response.body)
            uri = data['data']['uri'] # Update the application_params with the file URI

            answer = application.application_answers.find { |a| a.application_option_id == param[:application_option_id].to_i }
            answer.update!(answer: uri)
          else
            puts "Error uploading file: #{response.body}"
          end
        end
      end
    end

    # Simplifies HTTP requests to the Lever API
    def self.fetch_from_lever(url, client)
      uri = URI(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      request = Net::HTTP::Get.new(uri)
      request['accept'] = 'application/json'
      request['content-type'] = 'application/json'
      request['authorization'] = "Bearer #{validate_token(client)}"
      http.request(request)
    end

    # Builds the request body from the application answers and additional data
    def self.build_request_body(application)
      body = application.application_answers.map do |answer|
        # Check if answer.answer is a string that looks like an array
        answer_value = if answer.answer.is_a?(String) && answer.answer.start_with?('[') && answer.answer.end_with?(']')
                         # Parse the string as JSON to transform it into an array
                         JSON.parse(answer.answer)
                       else
                         # Use the answer as is
                         answer.answer
                       end
        {
          'question' => answer.application_option.ext_id.split('__', 2).last,
          'answer' => answer_value
        }
      end

      output = {
        'customQuestions' => [],
        'eeoResponses' => {},
        'diversitySurvey' => { 'surveyId' => '', 'candidateSelectedLocation' => '', 'responses' => [] },
        'personalInformation' => [],
        'urls' => []
      }

      LeverParser.parse(body, output)
    end

    # NOTE: LEVER_FETCH_POSTING_URL only returns the job; for the job options, use LEVER_GET_QUESTIONS_URL (see get_questions)
    # Reference: https://hire.sandbox.lever.co/developer/documentation#retrieve-a-single-posting
    def self.fetch_posting(posting_id, client, job)
      # Fetch job posting
      response = fetch_from_lever(LEVER_FETCH_POSTING_URL.gsub('postingId', posting_id), client)
      job = handle_response(response, 'posting', client, job)

      # Fetch job questions
      response = fetch_from_lever(LEVER_FETCH_QUESTIONS_URL.gsub('postingId', posting_id), client)
      handle_response(response, 'questions', client, job)

      handle_internal_job(client, job)
    end

    # Processes the response based on type (posting or questions)
    def self.handle_response(response, type, client, job)
      case response
      when Net::HTTPSuccess
        config_file = type == 'posting' ? 'lever_posting_config.json' : 'lever_application_options_config.json'
        config = JSON.parse(File.read("app/controllers/integrations/#{config_file}"))
        resp = JSON.parse(response.body)
        parsed_data = Mawsitsit.parse(resp, config, true)
        if type == 'posting'
          job = parsed_data
          job['job_slug'] = "lever__#{job['job_slug']}"
          job['user_id'] = client.id.to_i
          job
        else
          job['application_options_attributes'] = parsed_data['application_options_attributes']
        end
      when Net::HTTPBadRequest
        raise CustomExceptions::InvalidInput::Quicklink::Request::Malformed
      when Net::HTTPUnauthorized, Net::HTTPForbidden
        raise CustomExceptions::InvalidInput::Quicklink::ApiKey::Unauthorized
      end
    end

    # Check if the Lever access token is valid, otherwise use Lever refresh token to get a new one
    def self.validate_token(client) # rubocop:disable Metrics/AbcSize
      access_token = fetch_token(client, 'lever', 'access_token')
      return access_token unless access_token.nil?

      response_body = JSON.parse(lever_access_token(fetch_token!(client, 'lever', 'refresh_token')))
      IntegrationsController.save_token(user, 'OAuth Access Token', 'lever', 'access_token', response_body['access_token'], Time.now.utc + response_body['expires_in'], Time.now.utc)
      IntegrationsController.save_token(user, 'OAuth Refresh Token', 'lever', 'refresh_token', response_body['refresh_token'], Time.now.utc + 1.year, Time.now.utc)
      response_body['access_token']
    end

    # Retrieve a new access token using the refresh token (step 5)
    def self.lever_access_token(refresh_token)
      uri = URI.parse(LeverOauthController::LEVER_ACCESS_TOKEN_URL)
      http = Net::HTTP::Post.new(uri)
      http.use_ssl = true
      request.content_type = 'application/x-www-form-urlencoded'
      request.body = URI.encode_www_form({
                                           'client_id' => ENV.fetch('LEVER_CLIENT_ID', nil),
                                           'client_secret' => ENV.fetch('LEVER_CLIENT_SECRET', nil),
                                           'grant_type' => 'refresh_token',
                                           'refresh_token' => refresh_token
                                         })
      http.request(request)
    end
  end
end
