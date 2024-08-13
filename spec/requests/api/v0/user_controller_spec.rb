# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'UserController' do
  before(:all) do
    charset = ('a'..'z').to_a + ('A'..'Z').to_a

    ### USER CREATION ###

    # Create valid verified user without own jobs, upcoming jobs, reviews, ...
    @valid_user = User.create!(
      first_name: 'Max',
      last_name: 'Mustermann',
      email: "#{(0...16).map { charset.sample }.join}@embloy.com",
      password: 'password',
      password_confirmation: 'password',
      user_role: 'verified',
      activity_status: 1
    )

    # Create valid verified user with own jobs
    @valid_user_has_own_jobs = User.create!(
      first_name: 'Max',
      last_name: 'Mustermann',
      email: "#{(0...16).map { charset.sample }.join}@embloy.com",
      password: 'password',
      password_confirmation: 'password',
      user_role: 'verified',
      activity_status: 1
    )
    @valid_user_has_own_jobs.set_payment_processor :fake_processor, allow_fake: true
    @valid_user_has_own_jobs.pay_customers
    @valid_user_has_own_jobs.payment_processor.customer
    @valid_user_has_own_jobs.payment_processor.charge(19_00)
    @valid_user_has_own_jobs.payment_processor.subscribe(plan: 'price_1OUuWFKMiBrigNb6lfAf7ptj')

    # Create valid verified user with upcoming jobs
    @valid_user_has_upcoming_jobs = User.create!(
      first_name: 'Max',
      last_name: 'Mustermann',
      email: "#{(0...16).map { charset.sample }.join}@embloy.com",
      password: 'password',
      password_confirmation: 'password',
      user_role: 'verified',
      activity_status: 1
    )

    # Create valid unverified user
    @unverified_user = User.create!(
      first_name: 'Max',
      last_name: 'Mustermann',
      email: "#{(0...16).map { charset.sample }.join}@embloy.com",
      password: 'password',
      password_confirmation: 'password',
      user_role: 'spectator',
      activity_status: 0
    )

    # Blacklisted verified user
    @blacklisted_user = User.create!(
      first_name: 'Max',
      last_name: 'Mustermann',
      email: "#{(0...16).map { charset.sample }.join}@embloy.com",
      password: 'password',
      password_confirmation: 'password',
      user_role: 'verified',
      activity_status: 1
    )

    ### ACCESS / REFRESH TOKENS ###

    # Verified user refresh/access tokens
    credentials = Base64.strict_encode64("#{@valid_user.email}:password")
    headers = { 'Authorization' => "Basic #{credentials}" }
    post('/api/v0/auth/token/refresh', headers:)
    @valid_refresh_token = JSON.parse(response.body)['refresh_token']

    params = { 'grant_type' => 'refresh_token', 'refresh_token' => @valid_refresh_token }
    post('/api/v0/auth/token/access', params:)
    @valid_access_token = JSON.parse(response.body)['access_token']

    # Valid user with own jobs refresh/access tokens
    credentials = Base64.strict_encode64("#{@valid_user_has_own_jobs.email}:password")
    headers = { 'Authorization' => "Basic #{credentials}" }
    post('/api/v0/auth/token/refresh', headers:)
    @valid_rt_has_own_jobs = JSON.parse(response.body)['refresh_token']

    params = { 'grant_type' => 'refresh_token', 'refresh_token' => @valid_rt_has_own_jobs }
    post('/api/v0/auth/token/access', params:)
    @valid_at_has_own_jobs = JSON.parse(response.body)['access_token']

    # Valid user with upcoming jobs refresh/access tokens
    credentials = Base64.strict_encode64("#{@valid_user_has_upcoming_jobs.email}:password")
    headers = { 'Authorization' => "Basic #{credentials}" }
    post('/api/v0/auth/token/refresh', headers:)
    @valid_rt_has_upcoming_jobs = JSON.parse(response.body)['refresh_token']

    params = { 'grant_type' => 'refresh_token', 'refresh_token' => @valid_rt_has_upcoming_jobs }
    post('/api/v0/auth/token/access', params:)
    @valid_at_has_upcoming_jobs = JSON.parse(response.body)['access_token']

    # Blacklisted user refresh/access/client tokens
    credentials = Base64.strict_encode64("#{@blacklisted_user.email}:password")
    headers = { 'Authorization' => "Basic #{credentials}" }
    post('/api/v0/auth/token/refresh', headers:)
    @valid_rt_blacklisted = JSON.parse(response.body)['refresh_token']

    params = { 'grant_type' => 'refresh_token', 'refresh_token' => @valid_rt_blacklisted }
    post('/api/v0/auth/token/access', params:)
    @valid_at_blacklisted = JSON.parse(response.body)['access_token']

    UserBlacklist.create!(
      user_id: @blacklisted_user.id,
      reason: 'Test blacklist'
    )

    # Invalid/expired access tokens
    @invalid_access_token = 'eyJhbGciOiJIUzI1NiJ9.eyJzdWILOjQ6LCJleHAiOjE2OTgxNzk0MjgsImp0aSI6IjQ1NDMyZWUyNWE4YWUyMjc1ZGY0YTE2ZTNlNmQ0YTY4IiwiaWF0IjoxNjk4MTY1MDI4LCJpc3MiOiJDQl9TdXJmYWNlUHJvOCJ9.nqGgQ6Z52CbaHZzPGcwQG6U-nMDxb1yIe7HQMxjoDTs'

    # OWN JOBS & UPCOMING JOBS
    # Create own jobs for valid verified user (valid_user_has_own_jobs) and upcoming jobs for valid verified user (valid_user_has_upcoming_jobs)
    5.times do
      job = Job.create!(
        user_id: @valid_user_has_own_jobs.id
      )
      puts "Created new job for: #{@valid_user_has_own_jobs.id}"
      application = Application.create!(
        user_id: @valid_user_has_upcoming_jobs.id,
        job_id: job.id,
        response: 'No response yet ...'
      )
      application.accept('ACCEPTED')
      puts "#{@valid_user_has_upcoming_jobs.id} applied to #{job.id} and got accepted."
    end
  end

  describe 'User', type: :request do
    describe '(GET: /api/v0/user)' do
      context 'valid normal inputs' do
        it 'returns [200 Ok] and user JSON' do
          headers = { 'Authorization' => "Bearer #{@valid_access_token}" }
          get('/api/v0/user', headers:)
          expect(response).to have_http_status(200)
        end
      end
      context 'invalid inputs' do
        it 'returns [400 Bad Request] for missing access token in header' do
          get '/api/v0/user'
          expect(response).to have_http_status(400)
        end
        it 'returns [401 Unauthorized] for expired/invalid access token' do
          headers = { 'Authorization' => "Bearer #{@invalid_access_token}" }
          get('/api/v0/user', headers:)
          expect(response).to have_http_status(401)
        end
        it 'returns [403 Forbidden] for blacklisted user' do
          headers = { 'Authorization' => "Bearer #{@valid_at_blacklisted}" }
          get('/api/v0/user', headers:)
          expect(response).to have_http_status(403)
        end
      end
    end

    describe '(GET: /api/v0/user/verify)' do
      context 'valid normal inputs' do
        it 'returns [200 Ok] and new refresh token' do
          credentials = Base64.strict_encode64("#{@unverified_user.email}:password")
          headers = { 'Authorization' => "Basic #{credentials}" }
          get('/api/v0/user/verify', headers:)
          expect(response).to have_http_status(200)
        end
      end
      context 'invalid inputs' do
        it 'returns [400 Bad Request] for missing authentication' do
          get '/api/v0/user/verify'
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for missing email field' do
          credentials = Base64.strict_encode64(':password')
          headers = { 'Authorization' => "Basic #{credentials}" }
          get('/api/v0/user/verify', headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for missing password field' do
          credentials = Base64.strict_encode64(@valid_user.email.to_s)
          headers = { 'Authorization' => "Basic #{credentials}" }
          get('/api/v0/user/verify', headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [401 Unauthorized] for non-existing user' do
          credentials = Base64.strict_encode64('nonexistinguser@embloy.com:password')
          headers = { 'Authorization' => "Basic #{credentials}" }
          get('/api/v0/user/verify', headers:)
          expect(response).to have_http_status(401)
        end
        it 'returns [403 Forbidden] for blacklisted user' do
          credentials = Base64.strict_encode64("#{@blacklisted_user.email}:password")
          headers = { 'Authorization' => "Basic #{credentials}" }
          get('/api/v0/user/verify', headers:)
          expect(response).to have_http_status(403)
        end
        it 'returns [422 Unprocessable Entity] for already verified user' do
          credentials = Base64.strict_encode64("#{@valid_user.email}:password")
          headers = { 'Authorization' => "Basic #{credentials}" }
          get('/api/v0/user/verify', headers:)
          expect(response).to have_http_status(422)
        end
      end
    end

    describe '(GET: /api/v0/user/jobs)' do
      context 'valid normal inputs' do
        it 'returns [200 Ok] and job JSONs if user has own jobs' do
          headers = { 'Authorization' => "Bearer #{@valid_at_has_own_jobs}" }
          get('/api/v0/user/jobs', headers:)
          expect(response).to have_http_status(200)
        end
        it 'returns [204 No Content] if user does not have any jobs' do
          headers = { 'Authorization' => "Bearer #{@valid_access_token}" }
          get('/api/v0/user/jobs', headers:)
          expect(response).to have_http_status(204)
        end
      end
      context 'invalid inputs' do
        it 'returns [400 Bad Request] for missing access token in header' do
          get '/api/v0/user/jobs'
          expect(response).to have_http_status(400)
        end
        it 'returns [401 Unauthorized] for expired/invalid access token' do
          headers = { 'Authorization' => "Bearer #{@invalid_access_token}" }
          get('/api/v0/user/jobs', headers:)
          expect(response).to have_http_status(401)
        end
        it 'returns [403 Forbidden] for blacklisted user' do
          headers = { 'Authorization' => "Bearer #{@valid_at_blacklisted}" }
          get('/api/v0/user/jobs', headers:)
          expect(response).to have_http_status(403)
        end
      end
    end

    describe '(GET: /api/v0/user/upcoming)' do
      context 'valid normal inputs' do
        it 'returns [200 Ok] and JSON job JSONs if user has upcoming jobs' do
          headers = { 'Authorization' => "Bearer #{@valid_at_has_upcoming_jobs}" }
          get('/api/v0/user/upcoming', headers:)
          expect(response).to have_http_status(200)
        end
        it 'returns [204 No Content] if user does not have any jobs' do
          headers = { 'Authorization' => "Bearer #{@valid_access_token}" }
          get('/api/v0/user/upcoming', headers:)
          expect(response).to have_http_status(204)
        end
      end
      context 'invalid inputs' do
        it 'returns [400 Bad Request] for missing access token in header' do
          get '/api/v0/user/upcoming'
          expect(response).to have_http_status(400)
        end
        it 'returns [401 Unauthorized] for expired/invalid access token' do
          headers = { 'Authorization' => "Bearer #{@invalid_access_token}" }
          get('/api/v0/user/upcoming', headers:)
          expect(response).to have_http_status(401)
        end
        it 'returns [403 Forbidden] for blacklisted user' do
          headers = { 'Authorization' => "Bearer #{@valid_at_blacklisted}" }
          get('/api/v0/user/upcoming', headers:)
          expect(response).to have_http_status(403)
        end
      end
    end

    describe '(GET: /api/v0/user/preferences)' do
      context 'valid normal inputs' do
        it 'returns [200 Ok] and the preferences JSON' do
          headers = { 'Authorization' => "Bearer #{@valid_access_token}" }
          get('/api/v0/user/preferences', headers:)
          expect(response).to have_http_status(200)
        end
      end
      context 'invalid inputs' do
        it 'returns [400 Bad Request] for missing access token in header' do
          get '/api/v0/user/preferences'
          expect(response).to have_http_status(400)
        end
        it 'returns [401 Unauthorized] for expired/invalid access token' do
          headers = { 'Authorization' => "Bearer #{@invalid_access_token}" }
          get('/api/v0/user/preferences', headers:)
          expect(response).to have_http_status(401)
        end
        it 'returns [403 Forbidden] for blacklisted user' do
          headers = { 'Authorization' => "Bearer #{@valid_at_blacklisted}" }
          get('/api/v0/user/preferences', headers:)
          expect(response).to have_http_status(403)
        end
      end
    end

    describe '(GET: /api/v0/user/reviews)' do
      context 'valid normal inputs' do
        pending "GET:/user/review specs not implemented yet: #{__FILE__}"
        it 'returns [200 Ok] and user reviews' do
        end
      end
      context 'invalid inputs' do
        pending "GET:/user/review specs not implemented yet: #{__FILE__}"
        it 'returns [400 Bad Request] for missing access token in header' do
        end
        it 'returns [401 Unauthorized] for expired/invalid access token' do
        end
        it 'returns [403 Forbidden] for blacklisted user' do
        end
      end
    end

    describe '(POST: /api/v0/user)' do
      context 'valid normal inputs' do
        it 'returns [201 Created] and creates new user' do
          user_data = {
            user: {
              email: 'PostUserValidNormal@embloy.com',
              first_name: 'Max',
              last_name: 'Mustermann',
              password: 'password',
              password_confirmation: 'password'
            }
          }
          post '/api/v0/user', params: user_data.to_json, headers: { 'Content-Type' => 'application/json' }
          expect(response).to have_http_status(201)
        end
      end
      context 'invalid inputs' do
        it 'returns [400 Bad Request] for empty header' do
          post '/api/v0/user', headers: { 'Content-Type' => 'application/json' }
          expect(response).to have_http_status(400)
          post '/api/v0/user', params: nil, headers: { 'Content-Type' => 'application/json' }
          expect(response).to have_http_status(400)
          post '/api/v0/user', params: '', headers: { 'Content-Type' => 'application/json' }
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for missing email' do
          user_data = {
            user: {
              first_name: 'Max',
              last_name: 'Mustermann',
              password: 'password',
              password_confirmation: 'password'
            }
          }
          post '/api/v0/user', params: user_data.to_json, headers: { 'Content-Type' => 'application/json' }
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for missing first name' do
          user_data = {
            user: {
              email: 'PostUserMissingFirstName@embloy.com',
              last_name: 'Mustermann',
              password: 'password',
              password_confirmation: 'password'
            }
          }
          post '/api/v0/user', params: user_data.to_json, headers: { 'Content-Type' => 'application/json' }
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for missing last name' do
          user_data = {
            user: {
              email: 'PostUserMissingLastName@embloy.com',
              first_name: 'Max',
              password: 'password',
              password_confirmation: 'password'
            }
          }
          post '/api/v0/user', params: user_data.to_json, headers: { 'Content-Type' => 'application/json' }
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for missing password' do
          user_data = {
            user: {
              email: 'PostUserMissingPassword@embloy.com',
              first_name: 'Max',
              last_name: 'Mustermann',
              password_confirmation: 'password'
            }
          }
          post '/api/v0/user', params: user_data.to_json, headers: { 'Content-Type' => 'application/json' }
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for missing password confirmation' do
          user_data = {
            user: {
              email: 'PostUserMissingPasswordConfirmation@embloy.com',
              first_name: 'Max',
              last_name: 'Mustermann',
              password: 'password'
            }
          }
          post '/api/v0/user', params: user_data.to_json, headers: { 'Content-Type' => 'application/json' }
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for invalid email' do
          user_data = {
            user: {
              email: 'invalidemail',
              first_name: 'Max',
              last_name: 'Mustermann',
              password: '123456789',
              password_confirmation: '123456789'
            }
          }
          post '/api/v0/user', params: user_data.to_json, headers: { 'Content-Type' => 'application/json' }
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for too long email' do
          user_data = {
            user: {
              email: "#{'a' * 140}@embloy.com",
              first_name: 'Max',
              last_name: 'Mustermann',
              password: '123456789',
              password_confirmation: '123456789'
            }
          }
          post '/api/v0/user', params: user_data.to_json, headers: { 'Content-Type' => 'application/json' }
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for too long first name' do
          user_data = {
            user: {
              email: 'tooLongFirstName@embloy.com',
              first_name: 'a' * 129,
              last_name: 'Mustermann',
              password: '123456789',
              password_confirmation: '123456789'
            }
          }
          post '/api/v0/user', params: user_data.to_json, headers: { 'Content-Type' => 'application/json' }
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for too long last name' do
          user_data = {
            user: {
              email: 'TooLongLastName@embloy.com',
              first_name: 'Max',
              last_name: 'a' * 129,
              password: '123456789',
              password_confirmation: '123456789'
            }
          }
          post '/api/v0/user', params: user_data.to_json, headers: { 'Content-Type' => 'application/json' }
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for too long password' do
          user_data = {
            user: {
              email: 'TooLongPassword@embloy.com',
              first_name: 'Max',
              last_name: 'Mustermann',
              password: 'a' * 73,
              password_confirmation: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
            }
          }
          post '/api/v0/user', params: user_data.to_json, headers: { 'Content-Type' => 'application/json' }
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for too short password' do
          user_data = {
            user: {
              email: 'TooShortPassword@embloy.com',
              first_name: 'Max',
              last_name: 'Mustermann',
              password: '1234567',
              password_confirmation: '1234567'
            }
          }
          post '/api/v0/user', params: user_data.to_json, headers: { 'Content-Type' => 'application/json' }
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for password and password confirmation mismatch' do
          user_data = {
            user: {
              email: 'PostUserPasswordMismatch@embloy.com',
              first_name: 'Max',
              last_name: 'Mustermann',
              password: '123456789',
              password_confirmation: '987654321'
            }
          }
          post '/api/v0/user', params: user_data.to_json, headers: { 'Content-Type' => 'application/json' }
          expect(response).to have_http_status(400)
        end
        it 'returns [422 Unprocessable Entity] if the user already exists' do
          user_data = {
            user: {
              email: @valid_user.email,
              first_name: @valid_user.first_name,
              last_name: @valid_user.last_name,
              password: 'password',
              password_confirmation: 'password'
            }
          }
          post '/api/v0/user', params: user_data.to_json, headers: { 'Content-Type' => 'application/json' }
          expect(response).to have_http_status(422)
        end
      end
    end

    # TODO
    describe '(POST: /api/v0/user/image)' do
      context 'valid normal inputs' do
        pending "POST:/user/image specs not implemented yet: #{__FILE__}"
        it 'returns [200 Ok] and new image url' do
          'Not implemented'
        end
      end
      context 'invalid inputs' do
        it 'returns [400 Bad Request] for missing access token in header' do
          post '/api/v0/user/image'
          expect(response).to have_http_status(400)
        end
        it 'returns [401 Unauthorized] for expired/invalid access token' do
          headers = { 'Authorization' => "Bearer #{@invalid_access_token}" }
          post('/api/v0/user/image', headers:)
          expect(response).to have_http_status(401)
        end
        it 'returns [403 Forbidden] for blacklisted user' do
          headers = { 'Authorization' => "Bearer #{@valid_at_blacklisted}" }
          post('/api/v0/user/image', headers:)
          expect(response).to have_http_status(403)
        end
      end
    end

    # TODO: Test in depth
    describe '(PATCH: /api/v0/user)' do
      context 'valid normal inputs' do
        pending "PATCH:/user specs not implemented yet: #{__FILE__}"
        it 'returns [200 Ok] and updates the user' do
          'Not implemented'
        end
      end
      context 'invalid inputs' do
        it 'returns [400 Bad Request] for missing access token in header' do
          patch '/api/v0/user'
          expect(response).to have_http_status(400)
        end
        it 'returns [401 Unauthorized] for expired/invalid access token' do
          headers = { 'Authorization' => "Bearer #{@invalid_access_token}" }
          patch('/api/v0/user', headers:)
          expect(response).to have_http_status(401)
        end
        it 'returns [403 Forbidden] for blacklisted user' do
          headers = { 'Authorization' => "Bearer #{@valid_at_blacklisted}" }
          patch('/api/v0/user', headers:)
          expect(response).to have_http_status(403)
        end
      end
    end

    describe '(DELETE: /api/v0/user)' do
      context 'valid normal inputs' do
        it 'returns [200 Ok] and deletes the user' do
          headers = { 'Authorization' => "Bearer #{@valid_access_token}" }
          delete('/api/v0/user', headers:)
          expect(response).to have_http_status(200)
        end
      end
      context 'invalid inputs' do
        it 'returns [400 Bad Request] for missing access token in header' do
          delete '/api/v0/user'
          expect(response).to have_http_status(400)
        end
        it 'returns [401 Unauthorized] for expired/invalid access token' do
          headers = { 'Authorization' => "Bearer #{@invalid_access_token}" }
          delete('/api/v0/user', headers:)
          expect(response).to have_http_status(401)
        end
        it 'returns [403 Forbidden] for blacklisted user' do
          headers = { 'Authorization' => "Bearer #{@valid_at_blacklisted}" }
          delete('/api/v0/user', headers:)
          expect(response).to have_http_status(403)
        end
      end
    end
  end
end
