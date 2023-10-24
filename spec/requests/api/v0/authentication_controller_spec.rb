# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'AuthenticationController' do
  before do
    @valid_user = User.create(
      "first_name": "Max",
      "last_name": "Mustermann",
      "email": "validUser@embloy.com",
      "password": "password",
      "password_confirmation": "password",
      "user_role": "verified",
      "activity_status": "1"
    )
    puts"Created valid user: #{@valid_user.id}"

    @blacklisted_user = User.create!(
      "first_name": "Max",
      "last_name": "Mustermann",
      "email": "blacklistedUser@embloy.com",
      "password": "password",
      "password_confirmation": "password",
      "user_role": "verified"
      )
    puts"Created blacklisted user: #{@blacklisted_user.id}"
    UserBlacklist.create!(
      "user_id": @blacklisted_user.id,
      "reason": "Test blacklist"
    )

    @unverified_user = User.create!(
      "first_name": "Max",
      "last_name": "Mustermann",
      "email": "unverified@embloy.com",
      "password": "password",
      "password_confirmation": "password",
      "user_role": "spectator"
      )
    puts"Created unverified user: #{@unverified_user.id}"

  end

  describe "Refresh Token", type: :request do
    describe "(POST: /api/v0/user/auth/token/refresh)" do

      context 'valid normal inputs' do
        it 'returns [200 OK] and a new refresh token' do
          credentials = Base64.strict_encode64("#{@valid_user.email}:password")
          headers = { 'Authorization' => "Basic #{credentials}" }
          post '/api/v0/user/auth/token/refresh', headers: headers
          expect(response).to have_http_status(200)
        end
      end

      context 'invalid inputs' do
        it 'returns a [400 Bad Request] for missing authentication' do
          post '/api/v0/user/auth/token/refresh'
          expect(response).to have_http_status(400)
        end

        it 'returns [400 Bad Request] for missing email field' do
          credentials = Base64.strict_encode64(":password")
          headers = { 'Authorization' => "Basic #{credentials}" }
          post '/api/v0/user/auth/token/refresh', headers: headers
          expect(response).to have_http_status(400)
        end

        it 'returns [400 Bad Request] for missing password field' do
          credentials = Base64.strict_encode64("#{@valid_user.email}")
          headers = { 'Authorization' => "Basic #{credentials}" }
          post '/api/v0/user/auth/token/refresh', headers: headers
          expect(response).to have_http_status(400)
        end

        it 'returns [400 Bad Request] for non-existing user' do
          credentials = Base64.strict_encode64("nonexistinguser@embloy.com:password")
          headers = { 'Authorization' => "Basic #{credentials}" }
          post '/api/v0/user/auth/token/refresh', headers: headers
          expect(response).to have_http_status(401)
        end

        it 'returns [401 Unauthorized] for unverified user' do
          credentials = Base64.strict_encode64("#{@unverified_user.email}:password")
          headers = { 'Authorization' => "Basic #{credentials}" }
          post '/api/v0/user/auth/token/refresh', headers: headers
          expect(response).to have_http_status(403)
        end

        it 'returns [403 Forbidden] for blacklisted user' do
          credentials = Base64.strict_encode64("#{@blacklisted_user.email}:password")
          headers = { 'Authorization' => "Basic #{credentials}" }
          post '/api/v0/user/auth/token/refresh', headers: headers
          expect(response).to have_http_status(403)
        end
      end
    end
  end

  context 'when fetching access token' do
    it 'succeeds' do
      'Not implemented'
    end
  end

end
