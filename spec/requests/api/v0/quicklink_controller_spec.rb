# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'QuicklinkController' do
  before(:all) do
    charset = ('a'..'z').to_a + ('A'..'Z').to_a

    ### USER CREATION ###

    # Create valid verified user without own jobs, upcoming jobs, reviews, ...
    @valid_user = User.create!(
      "first_name": "Max",
      "last_name": "Mustermann",
      "email": "#{(0...16).map { charset.sample }.join}@embloy.com",
      "password": "password",
      "password_confirmation": "password",
      "user_role": "verified",
      "activity_status": "1"
    )
    puts "Created verified user without own jobs, upcoming jobs, reviews: #{@valid_user.id}"

    # Create valid verified user with own jobs
    @valid_user_has_own_jobs = User.create!(
      "first_name": "Max",
      "last_name": "Mustermann",
      "email": "#{(0...16).map { charset.sample }.join}@embloy.com",
      "password": "password",
      "password_confirmation": "password",
      "user_role": "verified",
      "activity_status": "1"
    )
    puts "Created valid verified user with own jobs: #{@valid_user_has_own_jobs.id}"
    @valid_user_has_own_jobs

    # Create valid verified user who already has applied
    @valid_user_has_applied = User.create!(
      "first_name": "Max",
      "last_name": "Mustermann",
      "email": "#{(0...16).map { charset.sample }.join}@embloy.com",
      "password": "password",
      "password_confirmation": "password",
      "user_role": "verified",
      "activity_status": "1"
    )
    puts "Created valid verified user who has already applied: #{@valid_user_has_applied.id}"
    @valid_user_has_applied

    # Create valid unverified user
    @unverified_user = User.create!(
      "first_name": "Max",
      "last_name": "Mustermann",
      "email": "#{(0...16).map { charset.sample }.join}@embloy.com",
      "password": "password",
      "password_confirmation": "password",
      "user_role": "spectator",
      "activity_status": "0"
    )
    puts "Created unverified user: #{@unverified_user.id}"

    # Blacklisted verified user
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

    ### ACCESS / REFRESH TOKENS ###

    # Verified user refresh/access/client tokens
    credentials = Base64.strict_encode64("#{@valid_user.email}:password")
    headers = { 'Authorization' => "Basic #{credentials}" }
    post '/api/v0/user/auth/token/refresh', headers: headers
    @valid_refresh_token = JSON.parse(response.body)['refresh_token']
    puts "Valid user refresh token: #{@valid_refresh_token}"

    headers = { "HTTP_REFRESH_TOKEN" => @valid_refresh_token }
    post '/api/v0/user/auth/token/access', headers: headers
    @valid_access_token = JSON.parse(response.body)['access_token']
    puts "Valid user access token: #{@valid_access_token}"

    headers = { "HTTP_ACCESS_TOKEN" => @valid_access_token }
    post '/api/v0/client/auth/token', headers: headers
    @valid_client_token = JSON.parse(response.body)['client_token']
    puts "Valid user client token: #{@valid_client_token}"

    # Valid user with own jobs refresh/access/client tokens
    credentials = Base64.strict_encode64("#{@valid_user_has_own_jobs.email}:password")
    headers = { 'Authorization' => "Basic #{credentials}" }
    post '/api/v0/user/auth/token/refresh', headers: headers
    @valid_rt_has_own_jobs = JSON.parse(response.body)['refresh_token']
    puts "Valid user with own jobs refresh token: #{@valid_rt_has_own_jobs}"

    headers = { "HTTP_REFRESH_TOKEN" => @valid_rt_has_own_jobs }
    post '/api/v0/user/auth/token/access', headers: headers
    @valid_at_has_own_jobs = JSON.parse(response.body)['access_token']
    puts "Valid user with own jobs access token: #{@valid_at_has_own_jobs}"

    headers = { "HTTP_ACCESS_TOKEN" => @valid_at_has_own_jobs }
    post '/api/v0/client/auth/token', headers: headers
    @valid_ct_has_own_jobs = JSON.parse(response.body)['client_token']
    puts "Valid user with own jobs client token: #{@valid_ct_has_own_jobs}"

    # Valid user who has applied refresh/access/client tokens
    credentials = Base64.strict_encode64("#{@valid_user_has_applied.email}:password")
    headers = { 'Authorization' => "Basic #{credentials}" }
    post '/api/v0/user/auth/token/refresh', headers: headers
    @valid_rt_has_applied = JSON.parse(response.body)['refresh_token']
    puts "Valid user who has applied jobs refresh token: #{@valid_rt_has_applied}"

    headers = { "HTTP_REFRESH_TOKEN" => @valid_rt_has_applied }
    post '/api/v0/user/auth/token/access', headers: headers
    @valid_at_has_applied = JSON.parse(response.body)['access_token']
    puts "Valid user who has applied access token: #{@valid_at_has_applied}"

    headers = { "HTTP_ACCESS_TOKEN" => @valid_at_has_applied }
    post '/api/v0/client/auth/token', headers: headers
    @valid_ct_has_applied = JSON.parse(response.body)['client_token']
    puts "Valid user who has applied client token: #{@valid_ct_has_applied}"

    # Blacklisted user refresh/access/client tokens
    credentials = Base64.strict_encode64("#{@blacklisted_user.email}:password")
    headers = { 'Authorization' => "Basic #{credentials}" }
    post '/api/v0/user/auth/token/refresh', headers: headers
    @valid_rt_blacklisted = JSON.parse(response.body)['refresh_token']
    puts "Valid user who will be blacklisted refresh token: #{@valid_rt_blacklisted}"

    headers = { "HTTP_REFRESH_TOKEN" => @valid_rt_blacklisted }
    post '/api/v0/user/auth/token/access', headers: headers
    @valid_at_blacklisted = JSON.parse(response.body)['access_token']
    puts "Valid user who will be blacklisted access token: #{@valid_at_blacklisted}"

    headers = { "HTTP_ACCESS_TOKEN" => @valid_at_blacklisted }
    post '/api/v0/client/auth/token', headers: headers
    @valid_ct_blacklisted = JSON.parse(response.body)['client_token']
    puts "Valid user who will be blacklisted access token: #{@valid_ct_blacklisted}"

    UserBlacklist.create!(
      "user_id": @blacklisted_user.id,
      "reason": "Test blacklist"
    )
    puts "Blacklisted user #{@blacklisted_user.id}}"


    # Invalid/expired access tokens
    @invalid_token = "eyJhbGciOiJIUzI1NiJ9.eyJzdWILOjQ6LCJleHAiOjE2OTgxNzk0MjgsImp0aSI6IjQ1NDMyZWUyNWE4YWUyMjc1ZGY0YTE2ZTNlNmQ0YTY4IiwiaWF0IjoxNjk4MTY1MDI4LCJpc3MiOiJDQl9TdXJmYWNlUHJvOCJ9.nqGgQ6Z52CbaHZzPGcwQG6U-nMDxb1yIe7HQMxjoDTs"

    # OWN JOBS & APPLIED JOBS
    # Create own jobs for valid verified user (valid_user_has_own_jobs) and applied jobs for valid verified user (valid_user_has_applied)
    5.times do
      job = Job.create!(
        user_id: @valid_user_has_own_jobs.id,
        title: "TestJob",
        description: "TestDescription",
        longitude: "0.0",
        latitude: "0.0",
        position: "Intern",
        salary: "123",
        start_slot: Time.now,
        key_skills: "Entrepreneurship",
        duration: "14",
        currency: "CHF",
        job_type: "Retail",
        job_type_value: "1"
      )
      puts "Created new job for: #{@valid_user_has_applied.id}"
      application = Application.create!(
        user_id: @valid_user_has_applied.id,
        job_id: job.id,
        application_text: "TestUpcomingApplicationText",
        response: "No response yet ..."
      )
      application.accept("ACCEPTED")
      puts "#{@valid_user_has_applied.id} applied to #{job.id} and got accepted."

    end
  end

  describe "Quicklink", type: :request do
    describe "(POST: /api/v0/client/auth/token)" do
        context 'valid normal inputs' do
            it 'returns [200 Ok] and new access token' do
                headers = { "HTTP_ACCESS_TOKEN" => @valid_access_token }
                post '/api/v0/client/auth/token', headers: headers
                expect(response).to have_http_status(200)
            end
        end
        context 'invalid inputs' do
            it 'returns [400 Bad Request] for missing refresh token in header' do
                post '/api/v0/client/auth/token'
                expect(response).to have_http_status(400)
            end
            it 'returns [401 Unauthorized] for expired/invalid refresh token' do
                headers = { "HTTP_ACCESS_TOKEN" => @invalid_token }
                post '/api/v0/client/auth/token', headers: headers
                expect(response).to have_http_status(401)
            end
            it 'returns [403 Forbidden] for blacklisted user' do
                headers = { "HTTP_ACCESS_TOKEN" => @valid_at_blacklisted }
                post '/api/v0/client/auth/token', headers: headers
                expect(response).to have_http_status(403)
            end
        end
    end

    describe "(POST: /api/v0/sdk/request/auth/token)" do
      context 'valid normal inputs' do
        it 'returns [200 Ok] and job JSONs if user has own jobs' do
            headers = { "HTTP_CLIENT_TOKEN" => @valid_ct_has_own_jobs }
            post '/api/v0/sdk/request/auth/token', headers: headers
            expect(response).to have_http_status(200)
        end
      end
      context 'invalid inputs' do
        it 'returns [400 Bad Request] for missing client token in header' do
            post '/api/v0/sdk/request/auth/token'
            expect(response).to have_http_status(400)
        end
        it 'returns [401 Unauthorized] for expired/invalid client token' do
            headers = { "HTTP_CLIENT_TOKEN" => @invalid_token }
            post '/api/v0/sdk/request/auth/token', headers: headers
            expect(response).to have_http_status(401)
        end
        it 'returns [403 Forbidden] for blacklisted user' do
            headers = { "HTTP_CLIENT_TOKEN" => @valid_ct_blacklisted }
            post '/api/v0/sdk/request/auth/token', headers: headers
            expect(response).to have_http_status(403)
        end
      end
    end

    # TODO: Test application via quicklink
=begin
    describe "(POST: /api/v0/sdk/applications)" do
      context 'valid normal inputs' do
        it 'returns [200 Ok] and JSON job JSONs if user has upcoming jobs' do
          headers = { "HTTP_ACCESS_TOKEN" => @valid_at_has_upcoming_jobs }
          get '/api/v0/sdk/applications', headers: headers
          expect(response).to have_http_status(200)
        end
        it 'returns [204 No Content] if user does not have any jobs' do
          headers = { "HTTP_ACCESS_TOKEN" => @valid_access_token }
          get '/api/v0/sdk/applications', headers: headers
          expect(response).to have_http_status(204)
        end
      end
      context 'invalid inputs' do
        it 'returns [400 Bad Request] for missing access token in header' do
          get '/api/v0/sdk/applications'
          expect(response).to have_http_status(400)
        end
        it 'returns [401 Unauthorized] for expired/invalid access token' do
          headers = { "HTTP_ACCESS_TOKEN" => @invalid_access_token }
          get '/api/v0/sdk/applications', headers: headers
          expect(response).to have_http_status(401)
        end
      end
    end
=end
  end
end
