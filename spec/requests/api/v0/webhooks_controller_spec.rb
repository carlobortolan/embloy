# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'WebhooksController', type: :request do
  before(:all) do
    charset = ('a'..'z').to_a + ('A'..'Z').to_a

    @valid_user = User.create!(
      first_name: 'Max',
      last_name: 'Mustermann',
      email: "#{(0...16).map { charset.sample }.join}@embloy.com",
      password: 'password',
      password_confirmation: 'password',
      user_role: 'verified',
      activity_status: 1
    )

    @blacklisted_user = User.create!(
      first_name: 'Max',
      last_name: 'Mustermann',
      email: "#{(0...16).map { charset.sample }.join}@embloy.com",
      password: 'password',
      password_confirmation: 'password',
      user_role: 'verified',
      activity_status: 1
    )

    # Verified user refresh/access/client tokens
    credentials = Base64.strict_encode64("#{@valid_user.email}:password")
    headers = { 'Authorization' => "Basic #{credentials}" }
    post('/api/v0/auth/token/refresh', headers:)
    @valid_refresh_token = JSON.parse(response.body)['refresh_token']

    params = { 'grant_type' => 'refresh_token', 'refresh_token' => @valid_refresh_token }
    post('/api/v0/auth/token/access', params:)
    @valid_access_token = JSON.parse(response.body)['access_token']

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

    @invalid_access_token = 'eyJhbGciOiJIUzI1NiJ9.eyJzdWILOjQ5LCJleHAiOjE2OTgxNzk0MjgsImp0aSI6IjQ1NDMyZWUyNWE4YWUyMjc1ZGY0YTE2ZTNlNmQ0YTY4IiwiaWF0IjoxNjk4MTY1MDI4LCJpc3MiOiJDQl9TdXJmYWNlUHJvOCJ9.nqGgQ6Z52CbaHZzPGcwQG6U-nMDxb1yIe7HQMxjoDTs'
  end

  describe 'GET /api/v0/user/webhooks' do
    context 'valid inputs' do
      it 'returns [204 No Content] for empty webhooks' do
        headers = { 'Authorization' => "Bearer #{@valid_access_token}" }
        get('/api/v0/user/webhooks', headers:)
        expect(response).to have_http_status(204)
      end

      it 'returns [200 OK] with webhooks' do
        Webhook.create!(user: @valid_user, url: 'https://api.embloy.com/api/v0/webhooks/ashby/e25ad8fdab066c4df683348872c08ec5', source: 'ashby',
                        ext_id: 'ashby__5dfc1294-2890-4678-bd8a-3180cf235005', event: 'job.create')
        headers = { 'Authorization' => "Bearer #{@valid_access_token}" }
        get('/api/v0/user/webhooks', headers:)
        expect(response).to have_http_status(200)
        expect(JSON.parse(response.body)['webhooks']).not_to be_empty
      end
    end

    context 'invalid inputs' do
      it 'returns [400 Bad Request] for missing authentication' do
        headers = { 'Content-Type' => 'application/json' }
        get('/api/v0/user/webhooks', headers:)
        expect(response).to have_http_status(400)
      end
      it 'returns [401 Unauthorized] for expired/invalid access token' do
        headers = { 'Authorization' => "Bearer #{@invalid_access_token}" }
        get('/api/v0/user/webhooks', headers:)
        expect(response).to have_http_status(401)
      end
      it 'returns [403 Forbidden] for blacklisted user' do
        headers = { 'Authorization' => "Bearer #{@valid_at_blacklisted}" }
        get('/api/v0/user/webhooks', headers:)
        expect(response).to have_http_status(403)
      end
    end
  end

  describe 'POST /api/v0/user/webhooks/:source' do
    context 'invalid inputs' do
      it 'returns [400 Bad Request] for missing authentication' do
        headers = { 'Content-Type' => 'application/json' }
        post('/api/v0/user/webhooks/lever', headers:)
        expect(response).to have_http_status(400)
      end
      it 'returns [401 Unauthorized] for expired/invalid access token' do
        headers = { 'Authorization' => "Bearer #{@invalid_access_token}" }
        post('/api/v0/user/webhooks/lever', headers:)
        expect(response).to have_http_status(401)
      end
      it 'returns [403 Forbidden] for blacklisted user' do
        headers = { 'Authorization' => "Bearer #{@valid_at_blacklisted}" }
        post('/api/v0/user/webhooks/lever', params: { source: 'lever' }, headers:)
        expect(response).to have_http_status(403)
      end
      it 'returns [400 Bad Request] for missing authentication' do
        headers = { 'Content-Type' => 'application/json' }
        post('/api/v0/user/webhooks/lever', headers:)
        expect(response).to have_http_status(400)
      end
      it 'returns [401 Unauthorized] for expired/invalid access token' do
        headers = { 'Authorization' => "Bearer #{@invalid_access_token}" }
        post('/api/v0/user/webhooks/lever', headers:)
        expect(response).to have_http_status(401)
      end
      it 'returns [403 Forbidden] for blacklisted user' do
        headers = { 'Authorization' => "Bearer #{@valid_at_blacklisted}" }
        post('/api/v0/user/webhooks/lever', params: { source: 'lever' }, headers:)
        expect(response).to have_http_status(403)
      end
      it 'returns [422 Unprocessable Entity] for unknown source' do
        headers = { 'Authorization' => "Bearer #{@valid_access_token}" }
        post('/api/v0/user/webhooks/unknown', headers:)
        expect(response).to have_http_status(422)
        expect(JSON.parse(response.body)['error']).to eq('Unknown source')
      end
    end
  end
end
