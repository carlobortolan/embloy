# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'SubscriptionsController' do
=begin
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
      activity_status: '1'
    )
    puts "Created verified user without own jobs, upcoming jobs, reviews: #{@valid_user.id}"

    # Create valid verified user with subscriptions
    @valid_user_has_subscriptions = User.create!(
      first_name: 'Max',
      last_name: 'Mustermann',
      email: "#{(0...16).map { charset.sample }.join}@embloy.com",
      password: 'password',
      password_confirmation: 'password',
      user_role: 'verified',
      activity_status: '1'
    )
    puts "Created verified user with subscriptions: #{@valid_user_has_subscriptions.id}"

    # Create valid unverified user
    @unverified_user = User.create!(
      first_name: 'Max',
      last_name: 'Mustermann',
      email: "#{(0...16).map { charset.sample }.join}@embloy.com",
      password: 'password',
      password_confirmation: 'password',
      user_role: 'spectator',
      activity_status: '0'
    )
    puts "Created unverified user: #{@unverified_user.id}"

    # Blacklisted verified user
    @blacklisted_user = User.create!(
      first_name: 'Max',
      last_name: 'Mustermann',
      email: "#{(0...16).map { charset.sample }.join}@embloy.com",
      password: 'password',
      password_confirmation: 'password',
      user_role: 'verified',
      activity_status: '1'
    )
    puts "Created blacklisted user: #{@blacklisted_user.id}"

    ### ACCESS / REFRESH TOKENS ###

    # Verified user refresh/access tokens
    credentials = Base64.strict_encode64("#{@valid_user.email}:password")
    headers = { 'Authorization' => "Basic #{credentials}" }
    post('/api/v0/user/auth/token/refresh', headers:)
    @valid_refresh_token = JSON.parse(response.body)['refresh_token']
    puts "Valid user refresh token: #{@valid_refresh_token}"

    headers = { 'HTTP_REFRESH_TOKEN' => @valid_refresh_token }
    post('/api/v0/user/auth/token/access', headers:)
    @valid_access_token = JSON.parse(response.body)['access_token']
    puts "Valid user access token: #{@valid_access_token}"

    # Verified user with subscriptions refresh/access tokens
    credentials = Base64.strict_encode64("#{@valid_user_has_subscriptions.email}:password")
    headers = { 'Authorization' => "Basic #{credentials}" }
    post('/api/v0/user/auth/token/refresh', headers:)
    @valid_rt_has_subscriptions = JSON.parse(response.body)['refresh_token']
    puts "Valid user with subscriptions refresh token: #{@valid_rt_has_subscriptions}"

    headers = { 'HTTP_REFRESH_TOKEN' => @valid_rt_has_subscriptions }
    post('/api/v0/user/auth/token/access', headers:)
    @valid_at_has_subscriptions = JSON.parse(response.body)['access_token']
    puts "Valid user access token: #{@valid_at_has_subscriptions}"

    # Blacklisted user refresh/access/client tokens
    credentials = Base64.strict_encode64("#{@blacklisted_user.email}:password")
    headers = { 'Authorization' => "Basic #{credentials}" }
    post('/api/v0/user/auth/token/refresh', headers:)
    @valid_rt_blacklisted = JSON.parse(response.body)['refresh_token']
    puts "Valid user who will be blacklisted refresh token: #{@valid_rt_blacklisted}"

    headers = { 'HTTP_REFRESH_TOKEN' => @valid_rt_blacklisted }
    post('/api/v0/user/auth/token/access', headers:)
    @valid_at_blacklisted = JSON.parse(response.body)['access_token']
    puts "Valid user who will be blacklisted access token: #{@valid_at_blacklisted}"

    UserBlacklist.create!(
      user_id: @blacklisted_user.id,
      reason: 'Test blacklist'
    )
    puts "Blacklisted user #{@blacklisted_user.id}}"

    # Invalid/expired access tokens
    @invalid_access_token = 'eyJhbGciOiJIUzI1NiJ9.eyJzdWILOjQ6LCJleHAiOjE2OTgxNzk0MjgsImp0aSI6IjQ1NDMyZWUyNWE4YWUyMjc1ZGY0YTE2ZTNlNmQ0YTY4IiwiaWF0IjoxNjk4MTY1MDI4LCJpc3MiOiJDQl9TdXJmYWNlUHJvOCJ9.nqGgQ6Z52CbaHZzPGcwQG6U-nMDxb1yIe7HQMxjoDTs'

    # SUBSCRIPTIONS
    # Create subscriptions for valid verified user (valid_user_has_subscriptions)
    @forbidden_subscription = Subscription.create!(
      user_id: @blacklisted_user.id,
      tier: 'basic',
      active: true,
      expiration_date: Time.now,
      start_date: Time.now,
      auto_renew: true,
      start_date: Time.now
    )
    @subscription = Subscription.create!(
      user_id: @valid_user_has_subscriptions.id,
      tier: 'basic',
      active: true,
      expiration_date: Time.now,
      start_date: Time.now,
      auto_renew: true,
      start_date: Time.now
    )
  end

  describe 'Subscription', type: :request do
    describe '(GET: /api/v0/client/subscriptions)' do
      context 'valid normal inputs' do
        it 'returns [200 Ok] and JSON job JSONs if user has subscriptions' do
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_at_has_subscriptions }
          get('/api/v0/client/subscriptions', headers:)
          expect(response).to have_http_status(200)
        end
        it 'returns [204 No Content] if user does not have any subscriptions' do
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_access_token }
          get('/api/v0/client/subscriptions', headers:)
          expect(response).to have_http_status(204)
        end
      end
      context 'invalid inputs' do
        it 'returns [400 Bad Request] for missing access token in header' do
          get '/api/v0/client/subscriptions'
          expect(response).to have_http_status(400)
        end
        it 'returns [401 Unauthorized] for expired/invalid access token' do
          headers = { 'HTTP_ACCESS_TOKEN' => @invalid_access_token }
          get('/api/v0/client/subscriptions', headers:)
          expect(response).to have_http_status(401)
        end
        it 'returns [403 Forbidden] for blacklisted user' do
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_at_blacklisted }
          get('/api/v0/client/subscriptions', headers:)
          expect(response).to have_http_status(403)
        end
      end
    end
  end
=end
end
