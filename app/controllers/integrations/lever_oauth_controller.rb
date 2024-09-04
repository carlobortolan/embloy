# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'
require 'jwt'

module Integrations
  # LeverOauthController handles all OAuth-related actions for Lever
  class LeverOauthController < Api::V0::ApiController
    LEVER_OAUTH_URL = 'https://sandbox-lever.auth0.com/authorize'
    LEVER_ACCESS_TOKEN_URL = 'https://sandbox-lever.auth0.com/oauth/token'
    LEVER_REDIRECT_URL = 'https://genius.embloy.com/settings?tab=secrets'

    before_action :must_be_verified!, only: %i[authorize]
    before_action :must_be_subscribed!, only: %i[authorize]
    skip_before_action :require_user_not_blacklisted!, only: %i[callback]
    skip_before_action :set_current_user, only: %i[callback]

    # Called via 'localhost:3000/integrations/auth/lever' and redirects to Lever OAuth app (step 1)
    # Reference: https://hire.sandbox.lever.co/developer/documentation#scopes
    def authorize
      client_id = ENV.fetch('LEVER_CLIENT_ID', nil)
      state = Current.user.signed_id(purpose: 'lever_oauth_state', expires_in: 1.hour)
      audience = 'https://api.sandbox.lever.co/v1/'
      scope = 'offline_access postings:write:admin uploads:write:admin webhooks:write:admin' # TODO: Add scopes required by webhooks

      redirect_to "#{LEVER_OAUTH_URL}?client_id=#{client_id}&redirect_uri=#{auth_lever_callback_url}&state=#{state}&response_type=code&scope=#{scope}&prompt=consent&audience=#{audience}",
                  allow_other_host: true
    end

    # Callback method for Lever OAuth app (step 2) to request access and refresh token (step 3)
    # Reference: https://hire.sandbox.lever.co/developer/documentation#authentication
    def callback
      redirect_to_error(params['error'], params['error_description']) and return if params['error']

      state = params['state']
      user = User.find_signed!(state, purpose: 'lever_oauth_state')
      redirect_to_error('invalid_state') and return unless user

      response = make_http_request(params['code'])
      handle_http_response(response, user)
    end

    private

    # Redirect to Genius client with error message if something goes wrong
    def redirect_to_error(error, description = nil)
      redirect_to "#{ENV.fetch('GENIUS_CLIENT_URL')}/settings?tab=integrations?error=#{error}&error_description=#{description}",
                  allow_other_host: true
    end

    # Make initial authorization request to Lever API (returns access token and refresh token)
    def make_http_request(code)
      url = URI.parse(LEVER_ACCESS_TOKEN_URL)
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true
      request = Net::HTTP::Post.new(url)
      request.content_type = 'application/x-www-form-urlencoded'
      request.body = URI.encode_www_form({
                                           'client_id' => ENV.fetch('LEVER_CLIENT_ID', nil),
                                           'client_secret' => ENV.fetch('LEVER_CLIENT_SECRET', nil),
                                           'grant_type' => 'authorization_code',
                                           'code' => code,
                                           'scope' => 'offline_access postings:write:admin uploads:write:admin webhooks:read:admin webhooks:write:admin stages:read:admin interviews:read:admin offers:read:admin opportunities:read:admin', # rubocop:disable Layout/LineLength
                                           'redirect_uri' => auth_lever_callback_url
                                         })

      http.request(request)
    end

    # Handle HTTP response from Lever authorization request and save new tokens
    def handle_http_response(response, user)
      puts "Response: #{response.inspect}"
      case response
      when Net::HTTPSuccess
        response_body = JSON.parse(response.body)
        puts "Auth Response body: #{response_body.inspect}"
        IntegrationsController.save_token(user, 'OAuth Access Token', 'lever', 'access_token', response_body['access_token'], Time.now.utc + response_body['expires_in'], Time.now.utc)
        IntegrationsController.save_token(user, 'OAuth Refresh Token', 'lever', 'refresh_token', response_body['refresh_token'], Time.now.utc + 1.year, Time.now.utc)
        Integrations::LeverWebhooksController.refresh_webhooks(user)
        redirect_to("#{ENV.fetch('GENIUS_CLIENT_URL')}/settings?tab=integrations?success=Successfully connected to Lever", allow_other_host: true)
      else
        exception_class = {
          'Net::HTTPUnauthorized' => CustomExceptions::InvalidInput::Quicklink::OAuth::Unauthorized,
          'Net::HTTPForbidden' => CustomExceptions::InvalidInput::Quicklink::OAuth::Forbidden,
          'Net::HTTPNotFound' => CustomExceptions::InvalidInput::Quicklink::OAuth::NotFound,
          'Net::HTTPNotAcceptable' => CustomExceptions::InvalidInput::Quicklink::OAuth::NotAcceptable
        }[response.class.name]
        raise exception_class if exception_class
      end
    end
  end
end
