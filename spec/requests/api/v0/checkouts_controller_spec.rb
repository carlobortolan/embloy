# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'CheckoutsController' do
  before(:all) do
    charset = ('a'..'z').to_a + ('A'..'Z').to_a

    ### USER CREATION ###

    # Create valid verified user without jobs, applications, ...
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
    @valid_user_has_subscriptions = User.create!(
      first_name: 'Max',
      last_name: 'Mustermann',
      email: "#{(0...16).map { charset.sample }.join}@embloy.com",
      password: 'password',
      password_confirmation: 'password',
      user_role: 'verified',
      activity_status: 1
    )
    @valid_user_has_subscriptions.set_payment_processor :fake_processor, allow_fake: true
    @valid_user_has_subscriptions.pay_customers
    @valid_user_has_subscriptions.payment_processor.customer
    @valid_user_has_subscriptions.payment_processor.charge(19_00)
    @valid_user_has_subscriptions.payment_processor.subscribe(plan: 'fake')

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

    # Valid user with subscriptions refresh/access tokens
    credentials = Base64.strict_encode64("#{@valid_user_has_subscriptions.email}:password")
    headers = { 'Authorization' => "Basic #{credentials}" }
    post('/api/v0/auth/token/refresh', headers:)
    @valid_rt_has_subscriptions = JSON.parse(response.body)['refresh_token']

    params = { 'grant_type' => 'refresh_token', 'refresh_token' => @valid_rt_has_subscriptions }
    post('/api/v0/auth/token/access', params:)
    @valid_at_has_subscriptions = JSON.parse(response.body)['access_token']

    # Blacklisted user refresh/access tokens
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
  end

  describe 'Checkouts', type: :request do
    describe '(GET: /api/v0/checkout/portal)' do
      context 'valid normal inputs' do
        it 'returns [400 Bad Request] if user has subscriptions' do
          headers = { 'Authorization' => 'Bearer ' + @valid_at_has_subscriptions }
          get('/api/v0/checkout/portal', headers:)
          expect(response).to have_http_status(400) # Stripe error due to fake processor
        end
      end
      context 'invalid inputs' do
        it 'returns [400 Bad Request] for missing access token in header' do
          get '/api/v0/checkout/portal'
          expect(response).to have_http_status(400)
        end
        it 'returns [401 Unauthorized] for expired/invalid access token' do
          headers = { 'Authorization' => 'Bearer ' + @invalid_access_token }
          get('/api/v0/checkout/portal', headers:)
          expect(response).to have_http_status(401)
        end
        it 'returns [403 Forbidden] if user does not have any subscriptions' do
          headers = { 'Authorization' => 'Bearer ' + @valid_access_token }
          get('/api/v0/checkout/portal', headers:)
          expect(response).to have_http_status(403)
        end
        it 'returns [403 Forbidden] for blacklisted user' do
          headers = { 'Authorization' => 'Bearer ' + @valid_at_blacklisted }
          get('/api/v0/checkout/portal', headers:)
          expect(response).to have_http_status(403)
        end
      end

      describe '(POST: /api/v0/checkout)' do
        context 'valid normal inputs' do
          it 'returns [400 Bad Request] if user has subscriptions' do
            headers = { 'Authorization' => 'Bearer ' + @valid_at_has_subscriptions }
            post('/api/v0/checkout', headers:)
            expect(response).to have_http_status(400) # Stripe error due to fake processor
          end
          it 'returns [400 Bad Request] if user does not have any subscriptions' do
            headers = { 'Authorization' => 'Bearer ' + @valid_access_token }
            post('/api/v0/checkout', headers:)
            expect(response).to have_http_status(400) # Stripe error due to fake processor
          end
        end
        context 'invalid inputs' do
          it 'returns [400 Bad Request] for missing access token in header' do
            post '/api/v0/checkout'
            expect(response).to have_http_status(400)
          end
          it 'returns [401 Unauthorized] for expired/invalid access token' do
            headers = { 'Authorization' => 'Bearer ' + @invalid_access_token }
            post('/api/v0/checkout', headers:)
            expect(response).to have_http_status(401)
          end
          it 'returns [403 Forbidden] for blacklisted user' do
            headers = { 'Authorization' => 'Bearer ' + @valid_at_blacklisted }
            post('/api/v0/checkout', headers:)
            expect(response).to have_http_status(403)
          end
        end
      end

      describe '(GET: /api/v0/checkout/subscription/success)' do
        context 'valid normal inputs' do
        end
        context 'invalid inputs' do
          it 'returns [400 Bad Request] for missing access token in header' do
            get '/api/v0/checkout/subscription/success?session_id=123'
            expect(response).to have_http_status(400)
          end
          it 'returns [400 Bad Request] for missing \'session_id\'' do
            headers = { 'Authorization' => 'Bearer ' + @valid_access_token }
            get('/api/v0/checkout/subscription/success', headers:)
            expect(response).to have_http_status(400)
          end
          it 'returns [400 Bad Request] for invalid session id' do
            headers = { 'Authorization' => 'Bearer ' + @valid_at_has_subscriptions }
            get('/api/v0/checkout/subscription/success?session_id=123', headers:)
            expect(response).to have_http_status(400) # Stripe error due to fake processor
          end
          it 'returns [401 Unauthorized] for expired/invalid access token' do
            headers = { 'Authorization' => 'Bearer ' + @invalid_access_token }
            get('/api/v0/checkout/subscription/success?session_id=123', headers:)
            expect(response).to have_http_status(401)
          end
          it 'returns [403 Forbidden] for blacklisted user' do
            headers = { 'Authorization' => 'Bearer ' + @valid_at_blacklisted }
            get('/api/v0/checkout/subscription/success?session_id=123', headers:)
            expect(response).to have_http_status(403)
          end
        end
      end

      describe '(GET: /api/v0/checkout/failure)' do
        context 'valid normal inputs' do
          it 'returns [204 No Content]' do
            headers = { 'Authorization' => 'Bearer ' + @valid_access_token }
            get('/api/v0/checkout/failure', headers:)
            expect(response).to have_http_status(204)
          end
        end
        context 'invalid inputs' do
          it 'returns [400 Bad Request] for missing access token in header' do
            get '/api/v0/checkout/failure?session_id=123'
            expect(response).to have_http_status(400)
          end
          it 'returns [401 Unauthorized] for expired/invalid access token' do
            headers = { 'Authorization' => 'Bearer ' + @invalid_access_token }
            get('/api/v0/checkout/failure?session_id=123', headers:)
            expect(response).to have_http_status(401)
          end
          it 'returns [403 Forbidden] for blacklisted user' do
            headers = { 'Authorization' => 'Bearer ' + @valid_at_blacklisted }
            get('/api/v0/checkout/failure?session_id=123', headers:)
            expect(response).to have_http_status(403)
          end
        end
      end

      describe '(GET: /api/v0/checkout/payment/success)' do
        context 'valid normal inputs' do
        end
        context 'invalid inputs' do
          it 'returns [400 Bad Request] for missing access token in header' do
            get '/api/v0/checkout/payment/success?session_id=123'
            expect(response).to have_http_status(400)
          end
          it 'returns [400 Bad Request] for missing \'session_id\'' do
            headers = { 'Authorization' => 'Bearer ' + @valid_access_token }
            get('/api/v0/checkout/payment/success', headers:)
            expect(response).to have_http_status(400)
          end
          it 'returns [400 Bad Request] for invalid session id' do
            headers = { 'Authorization' => 'Bearer ' + @valid_at_has_subscriptions }
            get('/api/v0/checkout/payment/success?session_id=123', headers:)
            expect(response).to have_http_status(400) # Stripe error due to fake processor
          end
          it 'returns [401 Unauthorized] for expired/invalid access token' do
            headers = { 'Authorization' => 'Bearer ' + @invalid_access_token }
            get('/api/v0/checkout/payment/success?session_id=123', headers:)
            expect(response).to have_http_status(401)
          end
          it 'returns [403 Forbidden] for blacklisted user' do
            headers = { 'Authorization' => 'Bearer ' + @valid_at_blacklisted }
            get('/api/v0/checkout/payment/success?session_id=123', headers:)
            expect(response).to have_http_status(403)
          end
        end
      end
    end
  end
end
