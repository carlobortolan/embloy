# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'PasswordResetsController' do
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

    @unverified_user = User.create!(
      first_name: 'Max',
      last_name: 'Mustermann',
      email: "#{(0...16).map { charset.sample }.join}@embloy.com",
      password: 'password',
      password_confirmation: 'password',
      user_role: 'spectator',
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

    UserBlacklist.create!(
      user_id: @blacklisted_user.id,
      reason: 'Test blacklist'
    )
    @valid_reset_token = @valid_user.signed_id(
      purpose: 'password_reset', expires_in: 15.minutes
    )
    @unverified_reset_token = @unverified_user.signed_id(
      purpose: 'password_reset', expires_in: 15.minutes
    )
    @blacklisted_reset_token = @blacklisted_user.signed_id(
      purpose: 'password_reset', expires_in: 15.minutes
    )
    @expired_token = @valid_user.signed_id(
      purpose: 'password_reset', expires_in: 0.minutes
    )
    @wrong_purpose_token = @valid_user.signed_id(
      purpose: 'wrong_purpose', expires_in: 15.minutes
    )
    @invalid_reset_token = 'eyJfcmFpbHMiOnsibWVzc2FnZSI6Ik1RPT0iLCJleHAiOiIyMDIzLTEyLTI2VDE3OjQ0OjU4LjA3OFoiLCJwdXIiOiJ1c2VyL3Bhc3N3b3JkX3Jlc2V0In19--d57cad3e713b4008c450fd9d13e5f992e64e9a65d8cc06731a92f14309f7c213'
  end

  describe 'Reset password', type: :request do
    describe '(PATCH: /api/v0/user/password/reset)' do
      context 'valid inputs' do
        it 'returns [202 Accepted] and initiates the password reset process for valid user' do
          headers = { 'Content-Type' => 'application/json' }
          post("/api/v0/user/password/reset?email=#{@valid_user.email}", headers:)
          expect(response).to have_http_status(202)
        end
        it 'returns [202 Accepted] and initiates the password reset process for unverified user' do
          headers = { 'Content-Type' => 'application/json' }
          post("/api/v0/user/password/reset?email=#{@unverified_user.email}", headers:)
          expect(response).to have_http_status(202)
        end
        it 'returns [202 Accepted] for trying to reset password of non-existing user' do
          headers = { 'Content-Type' => 'application/json' }
          post('/api/v0/user/password/reset?email=nonexistinguser@embloy.com', headers:)
          expect(response).to have_http_status(202)
        end
        it 'returns [202 Accepted] for trying to reset password of blocked user' do
          headers = { 'Content-Type' => 'application/json' }
          post("/api/v0/user/password/reset?email=#{@blacklisted_user.email}", headers:)
          expect(response).to have_http_status(202)
        end
      end
      context 'invalid inputs' do
        it 'returns [400 Bad Request] for missing email field' do
          headers = { 'Content-Type' => 'application/json' }
          post('/api/v0/user/password/reset', headers:)
          expect(response).to have_http_status(400)
        end
      end
    end

    describe '(PATCH: /api/v0/user/password/reset)' do
      context 'valid inputs' do
        it 'returns [200 OK] and resets the user\'s password' do
          data = JSON.dump({
                             user: {
                               password: 'password',
                               password_confirmation: 'password'
                             }
                           })
          headers = { 'Content-Type' => 'application/json' }
          patch("/api/v0/user/password/reset?token=#{@valid_reset_token}", params: data, headers:)
          expect(response).to have_http_status(200)
        end
        it 'returns [403 Forbidden] for unverified user' do
          data = JSON.dump({
                             user: {
                               password: 'password',
                               password_confirmation: 'password'
                             }
                           })
          headers = { 'Content-Type' => 'application/json' }
          patch("/api/v0/user/password/reset?token=#{@unverified_reset_token}", params: data, headers:)
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
        it 'returns [400 Bad Request] for expired token' do
          data = JSON.dump({
                             user: {
                               password_confirmation: 'password'
                             }
                           })
          headers = { 'Content-Type' => 'application/json' }
          patch("/api/v0/user/password/reset?token=#{@expired_token}", params: data, headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for wrong purpose token' do
          data = JSON.dump({
                             user: {
                               password_confirmation: 'password'
                             }
                           })
          headers = { 'Content-Type' => 'application/json' }
          patch("/api/v0/user/password/reset?token=#{@valid_reset_token}", params: data, headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for missing request body' do
          headers = { 'Content-Type' => 'application/json' }
          patch("/api/v0/user/password/reset?token=#{@valid_reset_token}", headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for missing password field' do
          data = JSON.dump({
                             user: {
                               password_confirmation: 'password'
                             }
                           })
          headers = { 'Content-Type' => 'application/json' }
          patch("/api/v0/user/password/reset?token=#{@wrong_purpose_token}", params: data, headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for missing password_confirmation field' do
          data = JSON.dump({
                             user: {
                               password: 'password'
                             }
                           })
          headers = { 'Content-Type' => 'application/json' }
          patch("/api/v0/user/password/reset?token=#{@valid_reset_token}", params: data, headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for blank password' do
          data = JSON.dump({
                             user: {
                               password: '',
                               password_confirmation: ''
                             }
                           })
          headers = { 'Content-Type' => 'application/json' }
          patch("/api/v0/user/password/reset?token=#{@valid_reset_token}", params: data, headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [403 Forbidden] for blacklisted user' do
          data = JSON.dump({
                             user: {
                               password: 'password',
                               password_confirmation: 'password'
                             }
                           })
          headers = { 'Content-Type' => 'application/json' }
          patch("/api/v0/user/password/reset?token=#{@blacklisted_reset_token}", params: data, headers:)
          expect(response).to have_http_status(403)
        end
        it 'returns [422 Unprocessable Content] for too short password (min 8 char)' do
          data = JSON.dump({
                             user: {
                               password: '1234657',
                               password_confirmation: '1234657'
                             }
                           })
          headers = { 'Content-Type' => 'application/json' }
          patch("/api/v0/user/password/reset?token=#{@valid_reset_token}", params: data, headers:)
          expect(response).to have_http_status(422)
        end
        it 'returns [422 Unprocessable Content] for too long password (max 72 char)' do
          data = JSON.dump({
                             user: {
                               password: 'passwordpasswordpasswordpasswordpasswordpasswordpasswordpasswordpasswordp',
                               password_confirmation: 'passwordpasswordpasswordpasswordpasswordpasswordpasswordpasswordpasswordp'
                             }
                           })
          headers = { 'Content-Type' => 'application/json' }
          patch("/api/v0/user/password/reset?token=#{@valid_reset_token}", params: data, headers:)
          expect(response).to have_http_status(422)
        end
        it 'returns [422 Unprocessable Content] for password and password_confirmation mismatch' do
          data = JSON.dump({
                             user: {
                               password: 'password',
                               password_confirmation: '12345678'
                             }
                           })
          headers = { 'Content-Type' => 'application/json' }
          patch("/api/v0/user/password/reset?token=#{@valid_reset_token}", params: data, headers:)
          expect(response).to have_http_status(422)
        end
      end
    end
  end
end
