# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'AuthenticationController' do
  before(:all) do
    charset = ('a'..'z').to_a + ('A'..'Z').to_a

    @valid_user = User.create!(
      "first_name": "Max",
      "last_name": "Mustermann",
      "email": "#{(0...16).map { charset.sample }.join}@embloy.com",
      "password": "password",
      "password_confirmation": "password",
      "user_role": "verified",
      "activity_status": "1"
    )
    puts "Created valid user: #{@valid_user.id}"

    @blacklisted_user = User.create!(
      "first_name": "Max",
      "last_name": "Mustermann",
      "email": "#{(0...16).map { charset.sample }.join}@embloy.com",
      "password": "password",
      "password_confirmation": "password",
      "user_role": "verified",
      "activity_status": "1"
    )
    puts "Created blacklisted user: #{@blacklisted_user.id}"

    @unverified_user = User.create!(
      "first_name": "Max",
      "last_name": "Mustermann",
      "email": "#{(0...16).map { charset.sample }.join}@embloy.com",
      "password": "password",
      "password_confirmation": "password",
      "user_role": "spectator"
    )
    puts "Created unverified user: #{@unverified_user.id}"

    credentials = Base64.strict_encode64("#{@valid_user.email}:password")
    headers = { 'Authorization' => "Basic #{credentials}" }
    post '/api/v0/user/auth/token/refresh', headers: headers
    @valid_refresh_token = JSON.parse(response.body)['refresh_token']
    puts "Valid refresh token: #{@valid_refresh_token}"


    credentials = Base64.strict_encode64("#{@blacklisted_user.email}:password")
    headers = { 'Authorization' => "Basic #{credentials}" }
    post '/api/v0/user/auth/token/refresh', headers: headers
    @valid_rt_blacklisted = JSON.parse(response.body)['refresh_token']
    puts "Valid refresh token for blacklisted user: #{@valid_rt_blacklisted}"
    UserBlacklist.create!(
      "user_id": @blacklisted_user.id,
      "reason": "Test blacklist"
    )

    @invalid_refresh_token = "eyJhbGciOiJIUzI1NiJ9.eyJzdWILOjQ5LCJleHAiOjE2OTgxNzk0MjgsImp0aSI6IjQ1NDMyZWUyNWE4YWUyMjc1ZGY0YTE2ZTNlNmQ0YTY4IiwiaWF0IjoxNjk4MTY1MDI4LCJpc3MiOiJDQl9TdXJmYWNlUHJvOCJ9.nqGgQ6Z52CbaHZzPGcwQG6U-nMDxb1yIe7HQMxjoDTs"
  end

  describe "Refresh Token", type: :request do
    describe "(POST: /api/v0/user/auth/token/refresh)" do
      context 'valid inputs' do
        it 'returns [200 OK] and a new refresh token' do
          credentials = Base64.strict_encode64("#{@valid_user.email}:password")
          headers = { 'Authorization' => "Basic #{credentials}" }
          post '/api/v0/user/auth/token/refresh', headers: headers
          expect(response).to have_http_status(200)
        end
      end

      context 'invalid inputs' do
        it 'returns [400 Bad Request] for missing authentication' do
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
        it 'returns [401 Unauthorized] for non-existing user' do
          credentials = Base64.strict_encode64("nonexistinguser@embloy.com:password")
          headers = { 'Authorization' => "Basic #{credentials}" }
          post '/api/v0/user/auth/token/refresh', headers: headers
          expect(response).to have_http_status(401)
        end
        it 'returns [403 Forbidden] for unverified user' do
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

  describe "Access Token", type: :request do
    describe "(POST: /api/v0/user/auth/token/access)" do
      context 'valid normal inputs' do
        it 'returns [200 Ok] and new access token' do
          headers = { "HTTP_REFRESH_TOKEN" => @valid_refresh_token }
          post '/api/v0/user/auth/token/access', headers: headers
          expect(response).to have_http_status(200)
        end
      end

      context 'invalid inputs' do
        it 'returns [400 Bad Request] for missing refresh token in header' do
          post '/api/v0/user/auth/token/access'
          expect(response).to have_http_status(400)
        end
        it 'returns [401 Unauthorized] for expired/invalid refresh token' do
          headers = { "HTTP_REFRESH_TOKEN" => @invalid_refresh_token }
          post '/api/v0/user/auth/token/access', headers: headers
          expect(response).to have_http_status(401)
        end
        it 'returns [200 OK] for blacklisted user' do # TODO: Should this return 200 OK or 403 Forbidden?
          headers = { "HTTP_REFRESH_TOKEN" => @valid_rt_blacklisted }
          post '/api/v0/user/auth/token/access', headers: headers
          expect(response).to have_http_status(200)
        end
      end
    end
  end
end