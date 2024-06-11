# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'
require 'jwt'

module Integrations
  # LeverController handles Lever-related actions
  class LeverController < IntegrationsController
    LEVER_OAUTH_URL = 'https://sandbox-lever.auth0.com/oauth/token'
    LEVER_POST_FORM_URL = 'https://api.sandbox.lever.co/v1/postings/postingId/apply?send_confirmation_email=true'
    LEVER_FETCH_POSTING_URL = 'https://api.sandbox.lever.co/v1/postings/postingId'
    LEVER_FETCH_QUESTIONS_URL = 'https://api.sandbox.lever.co/v1/postings/postingId/applicationQuestions'

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

    # NOTE: LEVER_FETCH_POSTING_URL only returns the job; for the job options, use LEVER_GET_QUESTIONS_URL (s. get_questions)
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

    # TODO: @cb Implement OAuth2.0 Authorization Code Flow
    def authorize
      client_id = 'odduLmYKvgG5sHr6IO5KskcSpuGA2D'
      redirect_uri = integrations_lever_callback_url
      state = 'vgG5sHr6'
      response_type = 'code'
      audience = 'https://api.sandbox.lever.co/v1/'
      scope = 'postings:read:admin'
      prompt = 'consent'

      redirect_to "https://sandbox-lever.auth0.com/authorize?client_id=#{client_id}&redirect_uri=#{redirect_uri}&state=#{state}&response_type=#{response_type}&scope=#{scope}&prompt=#{prompt}&audience=#{audience}",
                  allow_other_host: true
    end

    # TODO: @cb Implement OAuth2.0 Authorization Code Flow
    # rubocop:disable Metrics/AbcSize
    def callback
      redirect_to "https://embloy.com/dashboard/overview?error=#{params['error']}&error_description=#{params['error_description']}", allow_other_host: true and return if params['error']

      code = params['code']
      params['state']

      # TODO: @cb Verify state here

      url = URI.parse(LEVER_OAUTH_URL)

      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true

      request = Net::HTTP::Post.new(uri)
      request.basic_auth(ENV.fetch('LEVER_API_KEY', nil), '')
      request.content_type = 'application/x-www-form-urlencoded'
      request.body = URI.encode_www_form({
                                           'grant_type' => 'authorization_code',
                                           'client_id' => ENV.fetch('LEVER_CLIENT_ID', nil),
                                           'client_secret' => ENV.fetch('LEVER_CLIENT_SECRET', nil),
                                           'code' => code,
                                           'redirect_uri' => callback_url
                                         })

      response = http.request(request)
      # TODO: @cb Handle response
      puts response.read_body
    end
    # rubocop:enable Metrics/AbcSize

    private

    # Check if the Lever access token is valid, otherwise use Lever refresh token to get a new one
    def validate_token(client)
      access_token = fetch_token(client, 'lever', 'access_token')

      if access_token.nil? || token_expired?(access_token)
        refresh_token = fetch_token!(client, 'lever', 'refresh_token')
        access_token = lever_access_token(refresh_token)
      end

      access_token
    end

    # This method is redundant as fetch_token already checks if the token is expired
    def token_expired?(token)
      decoded_token = JWT.decode(token, nil, false)
      exp = decoded_token[0]['exp']

      Time.at(exp) < Time.now
    end

    # Retrieve a new access token using the refresh token
    def lever_access_token(refresh_token)
      uri = URI.parse(LEVER_OAUTH_URL)
      request = Net::HTTP::Post.new(uri)
      request.content_type = 'application/x-www-form-urlencoded'
      request.body = URI.encode_www_form({
                                           'grant_type' => 'refresh_token',
                                           'client_id' => 'odduLmYKvgG5sHr6IO5KskcSpuGA2D',
                                           'client_secret' => 'uLmYKvgG5sHr6IO5KskcSpuGA2Dodd',
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

    # TODO: @cb Implement OAuth2.0 Authorization Code Flow
    def authenticate
      redirect_to("#{ENV.fetch('CORE_CLIENT_URL')}/oauth/redirect?error=Invalid email or password", allow_other_host: true) and return if auth.info.email.nil?

      user = User.find_by(email: auth.info.email)
      handle_existing_user(user) if user.present?
    end

    # TODO: @cb Implement OAuth2.0 Authorization Code Flow
    def handle_existing_user(user)
      refresh_token = AuthenticationTokenService::Refresh::Encoder.call(user.id.to_i)
      redirect_to("#{ENV.fetch('CORE_CLIENT_URL')}/oauth/redirect?refresh_token=#{refresh_token}", allow_other_host: true) and return
    end
  end
end
