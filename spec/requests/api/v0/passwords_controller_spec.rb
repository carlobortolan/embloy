# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'PasswordsController' do
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

    @invalid_refresh_token = 'eyJhbGciOiJIUzI1NiJ9.eyJzdWILOjQ5LCJleHAiOjE2OTgxNzk0MjgsImp0aSI6IjQ1NDMyZWUyNWE4YWUyMjc1ZGY0YTE2ZTNlNmQ0YTY4IiwiaWF0IjoxNjk4MTY1MDI4LCJpc3MiOiJDQl9TdXJmYWNlUHJvOCJ9.nqGgQ6Z52CbaHZzPGcwQG6U-nMDxb1yIe7HQMxjoDTs'
  end

  describe 'Update password', type: :request do
    describe '(PATCH: /api/v0/user/password)' do
      context 'valid inputs' do
        it 'returns [200 OK] and updates the user\'s password' do
          data = JSON.dump({
                             user: {
                               password: 'password',
                               password_confirmation: 'password'
                             }
                           })
          headers = { 'Authorization' => "Bearer #{@valid_access_token}", 'Content-Type' => 'application/json' }
          patch('/api/v0/user/password', params: data, headers:)
          expect(response).to have_http_status(200)
        end
      end

      context 'invalid inputs' do
        it 'returns [400 Bad Request] for missing authentication' do
          data = JSON.dump({
                             user: {
                               password: 'password',
                               password_confirmation: 'password'
                             }
                           })
          headers = { 'Content-Type' => 'application/json' }
          patch('/api/v0/user/password', params: data, headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for missing request body' do
          headers = { 'Authorization' => "Bearer #{@valid_access_token}", 'Content-Type' => 'application/json' }
          patch('/api/v0/user/password', headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for missing password field' do
          data = JSON.dump({
                             user: {
                               password_confirmation: 'password'
                             }
                           })
          headers = { 'Authorization' => "Bearer #{@valid_access_token}", 'Content-Type' => 'application/json' }
          patch('/api/v0/user/password', params: data, headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for missing password_confirmation field' do
          data = JSON.dump({
                             user: {
                               password: 'password'
                             }
                           })
          headers = { 'Authorization' => "Bearer #{@valid_access_token}", 'Content-Type' => 'application/json' }
          patch('/api/v0/user/password', params: data, headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for blank password' do
          data = JSON.dump({
                             user: {
                               password: '',
                               password_confirmation: ''
                             }
                           })
          headers = { 'Authorization' => "Bearer #{@valid_access_token}", 'Content-Type' => 'application/json' }
          patch('/api/v0/user/password', params: data, headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [403 Forbidden] for blacklisted user' do
          data = JSON.dump({
                             user: {
                               password: 'password',
                               password_confirmation: 'password'
                             }
                           })
          headers = { 'Authorization' => "Bearer #{@valid_at_blacklisted}", 'Content-Type' => 'application/json' }
          patch('/api/v0/user/password', params: data, headers:)
          expect(response).to have_http_status(403)
        end
        it 'returns [422 Unprocessable Content] for too short password (min 8 char)' do
          data = JSON.dump({
                             user: {
                               password: '1234657',
                               password_confirmation: '1234657'
                             }
                           })
          headers = { 'Authorization' => "Bearer #{@valid_access_token}", 'Content-Type' => 'application/json' }
          patch('/api/v0/user/password', params: data, headers:)
          expect(response).to have_http_status(422)
        end
        it 'returns [422 Unprocessable Content] for too long password (max 72 char)' do
          data = JSON.dump({
                             user: {
                               password: 'passwordpasswordpasswordpasswordpasswordpasswordpasswordpasswordpasswordp',
                               password_confirmation: 'passwordpasswordpasswordpasswordpasswordpasswordpasswordpasswordpasswordp'
                             }
                           })
          headers = { 'Authorization' => "Bearer #{@valid_access_token}", 'Content-Type' => 'application/json' }
          patch('/api/v0/user/password', params: data, headers:)
          expect(response).to have_http_status(422)
        end
        it 'returns [422 Unprocessable Content] for password and password_confirmation mismatch' do
          data = JSON.dump({
                             user: {
                               password: 'password',
                               password_confirmation: '12345678'
                             }
                           })
          headers = { 'Authorization' => "Bearer #{@valid_access_token}", 'Content-Type' => 'application/json' }
          patch('/api/v0/user/password', params: data, headers:)
          expect(response).to have_http_status(422)
        end
      end
    end
  end
end
