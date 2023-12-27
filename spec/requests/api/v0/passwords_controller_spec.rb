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
      activity_status: '1'
    )
    puts "Created valid user: #{@valid_user.id}"

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

    # Verified user refresh/access/client tokens
    credentials = Base64.strict_encode64("#{@valid_user.email}:password")
    headers = { 'Authorization' => "Basic #{credentials}" }
    post('/api/v0/user/auth/token/refresh', headers:)
    @valid_refresh_token = JSON.parse(response.body)['refresh_token']
    puts "Valid user refresh token: #{@valid_refresh_token}"

    headers = { 'HTTP_REFRESH_TOKEN' => @valid_refresh_token }
    post('/api/v0/user/auth/token/access', headers:)
    @valid_access_token = JSON.parse(response.body)['access_token']
    puts "Valid user access token: #{@valid_access_token}"

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
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_access_token, 'Content-Type' => 'application/json' }
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
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_access_token, 'Content-Type' => 'application/json' }
          patch('/api/v0/user/password', headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for missing password field' do
          data = JSON.dump({
                             user: {
                               password_confirmation: 'password'
                             }
                           })
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_access_token, 'Content-Type' => 'application/json' }
          patch('/api/v0/user/password', params: data, headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for missing password_confirmation field' do
          data = JSON.dump({
                             user: {
                               password: 'password'
                             }
                           })
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_access_token, 'Content-Type' => 'application/json' }
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
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_access_token, 'Content-Type' => 'application/json' }
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
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_at_blacklisted, 'Content-Type' => 'application/json' }
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
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_access_token, 'Content-Type' => 'application/json' }
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
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_access_token, 'Content-Type' => 'application/json' }
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
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_access_token, 'Content-Type' => 'application/json' }
          patch('/api/v0/user/password', params: data, headers:)
          expect(response).to have_http_status(422)
        end
      end
    end
  end
end
