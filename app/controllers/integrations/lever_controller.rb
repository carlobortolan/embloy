# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'

module Integrations
  # LeverController handles oauth-related actions
  class LeverController < ApplicationController
    skip_before_action :require_user_not_blacklisted!

    LEVER_OAUTH_URL = 'https://sandbox-lever.auth0.com/oauth/token'

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

    # rubocop:disable Metrics/AbcSize
    def callback
      redirect_to "https://embloy.com/dashboard/overview?error=#{params['error']}&error_description=#{params['error_description']}", allow_other_host: true and return if params['error']

      code = params['code']
      params['state']

      # TODO: Verify state here

      uri = URI.parse(LEVER_OAUTH_URL)
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

      req_options = {
        use_ssl: uri.scheme == 'https'
      }

      response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
        http.request(request)
      end

      # TODO: Handle response
      puts response.body
    end
    # rubocop:enable Metrics/AbcSize

    def self.submit_form(posting_id, application_details)
      puts 'STARTING TO SEND TO LEVER'
      uri = URI.parse("https://api.sandbox.lever.co/v1/postings/#{posting_id}/apply?send_confirmation_email=true")

      request = Net::HTTP::Post.new(uri)
      request['Content-Type'] = 'application/json'
      request['Authorization'] = "Basic #{Base64.strict_encode64(ENV.fetch('LEVER_API_KEY', ''))}"
      request.body = application_details.to_json

      req_options = {
        use_ssl: uri.scheme == 'https'
      }

      response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
        http.request(request)
      end

      # TODO: Handle response
      puts response.body
    end

    def self.get_posting(posting_id, client, job)
      # TODO: CALL POSTINGS API to fetch/update job

      if job.nil?
        job = Job.new(job_slug: "lever__#{posting_id}", user_id: client.id.to_i)
        job.save!
        job.user = client
        client.jobs << job
      else
        job.update!(title: 'test')
      end
      job
    end

    def self.get_questions(posting_id, client, job)
      # TODO: CALL POSTINGS API to fetch/update application options
    end

    private

    def valid_token?(access_token)
      # Implement your logic to validate the token here
    end

    def refresh_token(refresh_token)
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

    def authenticate
      redirect_to("#{ENV.fetch('CORE_CLIENT_URL')}/oauth/redirect?error=Invalid email or password", allow_other_host: true) and return if auth.info.email.nil?

      user = User.find_by(email: auth.info.email)
      handle_existing_user(user) if user.present?
    end

    def handle_existing_user(user)
      refresh_token = AuthenticationTokenService::Refresh::Encoder.call(user.id.to_i)
      redirect_to("#{ENV.fetch('CORE_CLIENT_URL')}/oauth/redirect?refresh_token=#{refresh_token}", allow_other_host: true) and return
    end
  end
end
