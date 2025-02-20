# frozen_string_literal: true

require 'net/http'
require 'net/http/post/multipart'
require 'uri'
require 'json'
require 'jwt'

module Integrations
  module Lever
    # LeverController handles internal actions used by an Embloy SDK or API controller
    class LeverController < IntegrationsController
      API_URL = 'https://api.lever.co/v1'
      SANDBOX_API_URL = 'https://api.sandbox.lever.co/v1'
      POST_FORM_PATH = '/postings/postingId/apply?send_confirmation_email=true'
      POST_FILE_PATH = '/uploads'
      FETCH_POSTING_PATH = '/postings/postingId'
      FETCH_QUESTIONS_PATH = '/postings/postingId/apply?send_confirmation_email=true'

      ### APPLICATION SUBMISSION ###

      # Posts application form to Lever API
      # Reference: https://hire.sandbox.lever.co/developer/documentation#apply-to-a-posting
      def self.post_form(job, application, application_params, client, session)
        handle_lever_file_uploads(application, application_params, client)

        # Build and send request
        url = api_url(client, POST_FORM_PATH.gsub('postingId', job.job_slug.sub('lever__', '')))
        http = Net::HTTP.new(url.host, url.port)
        http.use_ssl = true
        request = Net::HTTP::Post.new(url)
        request['accept'] = 'application/json'
        request['content-type'] = 'application/json'
        request['authorization'] = "Bearer #{validate_token(client)}"
        request.body = build_request_body(application, session)

        response = http.request(request)

        Rails.logger.debug("Sending application to URL #{url}: #{request.body}, with response: #{response.body}")
        # Set external ID to save the application ID for webhook events
        if response.is_a?(Net::HTTPSuccess)
          response_data = JSON.parse(response.body)
          application_id = response_data['data']['applicationId']
          application.update!(ext_id: "lever__#{application_id}")
        end

        # Handle response
        handle_application_response(response)
      end

      # Handles file uploads for Lever
      def self.handle_lever_file_uploads(application, application_params, client) # rubocop:disable Metrics/AbcSize
        application_params[:application_answers].each_value do |param|
          next unless param[:file].present?

          url = api_url(client, POST_FILE_PATH)
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

              answer = application.application_answers.includes(:application, :application_option, :user, :job, :attachment_attachment).find do |a|
                a.application_option_id == param[:application_option_id].to_i && a.version == application.version
              end
              Rails.logger.debug("Updating answerid #{param[:application_option_id].to_i} with file URI: #{uri}")
              answer&.update!(answer: uri)
            else
              Rails.logger.error("Error uploading file: #{response.body}")
            end
          end
        end
      end

      # Simplifies HTTP requests to the Lever API
      def self.fetch_from_lever(path, client)
        url = api_url(client, path)
        http = Net::HTTP.new(url.host, url.port)
        http.use_ssl = true
        request = Net::HTTP::Get.new(url)
        request['authorization'] = "Bearer #{validate_token(client)}"
        http.request(request)
      end

      def self.api_url(client, path = '')
        URI((client.sandboxd? ? SANDBOX_API_URL : API_URL) + path)
      end

      # Builds the request body for the newest application version from the application answers and additional data
      def self.build_request_body(application, session) # rubocop:disable Metrics/AbcSize
        Rails.logger.debug("Building request body for application: #{application.inspect} with session: #{session.inspect}")

        body = application.application_answers.includes(:application, :application_option, :user, :job, :attachment_attachment).select do |answer|
          answer.version == application.version
        end.map do |answer| # rubocop:disable Style/MultilineBlockChain
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
          'urls' => [],
          'source' => extract_source_from_url(session['origin']),
          'origin' => extract_origin_from_url(session['origin'])
        }

        Rails.logger.debug("source: #{output['source']}, origin: #{output['origin']}")

        Parser.parse(body, output)
      end

      # Extract the source from the referrer URL
      def self.extract_source_from_url(url = nil)
        query_params = CGI.parse(URI.parse(url).query || '')
        source = query_params['lever-source[]'].first
        source ? "Embloy, #{source}" : 'Embloy'
      rescue URI::InvalidURIError
        'Embloy'
      end

      def self.extract_origin_from_url(url = nil)
        query_params = CGI.parse(URI.parse(url).query || '')
        query_params['lever-origin'].first || 'applied'
      rescue URI::InvalidURIError
        'applied'
      end

      # Deprecated method used for fetching job postings on every application - now handled by the sync_postings method
      # NOTE: FETCH_POSTING_PATH only returns the job; for the job options, use GET_QUESTIONS_PATH (see get_questions)
      # Reference: https://hire.sandbox.lever.co/developer/documentation#retrieve-a-single-posting
      def self.fetch_posting(posting_id, client, job)
        # Fetch job posting
        response = fetch_from_lever(FETCH_POSTING_PATH.gsub('postingId', posting_id), client)
        job = handle_response(response, 'posting', client, job)
        Rails.logger.debug("Received job: #{job}")
        # Fetch job questions
        response = fetch_from_lever(FETCH_QUESTIONS_PATH.gsub('postingId', posting_id), client)
        handle_response(response, 'questions', client, job)

        handle_internal_job(client, job)
      end

      # Processes the response based on type (posting or questions)
      def self.handle_response(response, type, client, job)
        case response
        when Net::HTTPSuccess
          config_file = type == 'posting' ? 'lever_posting_config.json' : 'lever_application_options_config.json'
          config = JSON.parse(File.read("app/controllers/integrations/lever/#{config_file}"))
          resp = JSON.parse(response.body)
          parsed_data = Mawsitsit.parse(resp, config, true)
          if type == 'posting'
            job = parsed_data
            job['job_slug'] = "lever__#{job['job_slug']}"
            job['user_id'] = client.id.to_i
            job
          else
            Rails.logger.debug("Received questions for job: #{job}")
            job['application_options_attributes'] = parsed_data['application_options_attributes']
          end
        when Net::HTTPBadRequest
          raise CustomExceptions::InvalidInput::Quicklink::Request::Malformed
        when Net::HTTPUnauthorized
          raise CustomExceptions::InvalidInput::Quicklink::OAuth::Unauthorized
        when Net::HTTPForbidden
          raise CustomExceptions::InvalidInput::Quicklink::OAuth::Forbidden
        when Net::HTTPNotFound
          raise CustomExceptions::InvalidInput::Quicklink::Request::NotFound
        end
      end

      ### JOB HANDLING ###

      # Fetches all jobs from Lever and saves, updates, or deletes them in the database
      def self.synchronize(client) # rubocop:disable Metrics/AbcSize
        response = fetch_from_lever(FETCH_POSTING_PATH.gsub('/postingId', ''), client)

        parsed_jobs = []

        case response
        when Net::HTTPSuccess
          config = JSON.parse(File.read('app/controllers/integrations/lever/lever_posting_config.json'))
          # TODO: Update MawSitSit to handle arrays of objects
          data = JSON.parse(response.body)['data']

          data.each do |job|
            parsed_job = Mawsitsit.parse({ data: job }, config, true)
            parsed_job['job_slug'] = "lever__#{parsed_job['job_slug']}"
            parsed_job['user_id'] = client.id.to_i
            parsed_job['application_options_attributes'] = []
            Rails.logger.debug("Received job: #{parsed_job}")
            # Fetch job questions
            questions = fetch_from_lever(FETCH_QUESTIONS_PATH.gsub('postingId', job['id']), client)
            Rails.logger.debug("Received questions for job: #{job['id']}: #{questions.body}")
            handle_response(questions, 'questions', client, parsed_job)

            parsed_jobs << parsed_job
            # handle_internal_job(client, parsed_job)
          end

          handle_internal_jobs(client, parsed_jobs)
        when Net::HTTPBadRequest
          raise CustomExceptions::InvalidInput::Quicklink::Request::Malformed
        when Net::HTTPUnauthorized
          raise CustomExceptions::InvalidInput::Quicklink::OAuth::Unauthorized
        when Net::HTTPForbidden
          raise CustomExceptions::InvalidInput::Quicklink::OAuth::Forbidden
        end
      end

      ### AUTHENTICATION ###

      # Check if the Lever access token is valid, otherwise use Lever refresh token to get a new one
      def self.validate_token(client) # rubocop:disable Metrics/AbcSize
        access_token = Token.fetch_token(client, 'lever', 'access_token')
        return access_token unless access_token.nil?

        response_body = JSON.parse(lever_access_token(Token.fetch_token!(client, 'lever', 'refresh_token'), client))
        Rails.logger.debug("Received new access token: #{response_body['access_token']}")
        Rails.logger.debug("Token expires in: #{response_body['expires_in']} seconds")
        Rails.logger.debug("With refresh token: #{response_body['refresh_token']}")
        Token.save_token(client, 'OAuth Access Token', 'lever', 'access_token', response_body['access_token'], Time.now.utc + response_body['expires_in'].to_i, Time.now.utc)
        Token.save_token(client, 'OAuth Refresh Token', 'lever', 'refresh_token', response_body['refresh_token'], Time.now.utc + 1.year, Time.now.utc)
        response_body['access_token']
      end

      # Retrieve a new access token using the refresh token (step 5)
      def self.lever_access_token(refresh_token, client)
        Rails.logger.debug("Refreshing Lever access token for client: #{client.id}")
        uri = OauthController.oauth_url(client, OauthController::ACCESS_TOKEN_PATH)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        request = Net::HTTP::Post.new(uri)
        request.content_type = 'application/x-www-form-urlencoded'
        request.body = URI.encode_www_form({
                                             'client_id' => ENV.fetch(client.sandboxd? ? 'LEVER_SANDBOX_CLIENT_ID' : 'LEVER_CLIENT_ID', nil),
                                             'client_secret' => ENV.fetch(client.sandboxd? ? 'LEVER_SANDBOX_CLIENT_SECRET' : 'LEVER_CLIENT_SECRET', nil),
                                             'grant_type' => 'refresh_token',
                                             'refresh_token' => refresh_token
                                           })

        Rails.logger.debug("Sending request to URL #{uri}: #{request.body}")
        response = http.request(request)

        Rails.logger.debug("Received response: #{response.body}")
        case response
        when Net::HTTPSuccess
          response.body
        when Net::HTTPBadRequest
          raise CustomExceptions::InvalidInput::Quicklink::Request::Malformed
        when Net::HTTPUnauthorized
          raise CustomExceptions::InvalidInput::Quicklink::OAuth::Unauthorized
        when Net::HTTPForbidden
          raise CustomExceptions::InvalidInput::Quicklink::OAuth::Forbidden
        end
      end
    end
  end
end
