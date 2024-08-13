# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'NotificationsController' do
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

    @user_has_notifications = User.create!(
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

    credentials = Base64.strict_encode64("#{@user_has_notifications.email}:password")
    headers = { 'Authorization' => "Basic #{credentials}" }
    post('/api/v0/auth/token/refresh', headers:)
    @valid_rt_has_notifications = JSON.parse(response.body)['refresh_token']

    params = { 'grant_type' => 'refresh_token', 'refresh_token' => @valid_rt_has_notifications }
    post('/api/v0/auth/token/access', params:)
    @valid_at_has_notifications = JSON.parse(response.body)['access_token']

    credentials = Base64.strict_encode64("#{@blacklisted_user.email}:password")
    headers = { 'Authorization' => "Basic #{credentials}" }
    post('/api/v0/auth/token/refresh', headers:)
    @valid_rt_blacklisted = JSON.parse(response.body)['refresh_token']

    params = { 'grant_type' => 'refresh_token', 'refresh_token' => @valid_rt_blacklisted }
    post('/api/v0/auth/token/access', params:)
    @valid_at_blacklisted = JSON.parse(response.body)['access_token']

    ApplicationStatusNotification.with(application: { user_id: @valid_user.id.to_i, job: 4 }, user_email: @valid_user.email, user_first_name: @valid_user.first_name, job_title: 'Job.first.title',
                                       status: -1, response: 'GG').deliver(@valid_user)
    ApplicationNotification.with(application: { user_id: @valid_user.id.to_i, job_id: 1 }, job_title: 'job.title || job.job_slug', job_notifications: 0).deliver(@valid_user)
    @notification = Notification.where(recipient: @valid_user).first

    ApplicationNotification.with(application: { user_id: @blacklisted_user.id.to_i, job_id: 1 }, job_title: 'job.title || job.job_slug', job_notifications: 0).deliver(@blacklisted_user)
    @blacklisted_notification = Notification.where(recipient: @blacklisted_user).first

    ApplicationNotification.with(application: { user_id: @user_has_notifications.id.to_i, job_id: 1 }, job_title: 'job.title || job.job_slug', job_notifications: 0).deliver(@user_has_notifications)
    @not_owned_notification = Notification.where(recipient: @user_has_notifications).first

    UserBlacklist.create!(
      user_id: @blacklisted_user.id,
      reason: 'Test blacklist'
    )

    @invalid_access_token = 'eyJhbGciOiJIUzI1NiJ9.eyJzdWILOjQ5LCJleHAiOjE2OTgxNzk0MjgsImp0aSI6IjQ1NDMyZWUyNWE4YWUyMjc1ZGY0YTE2ZTNlNmQ0YTY4IiwiaWF0IjoxNjk4MTY1MDI4LCJpc3MiOiJDQl9TdXJmYWNlUHJvOCJ9.nqGgQ6Z52CbaHZzPGcwQG6U-nMDxb1yIe7HQMxjoDTs'
  end

  describe 'Get latest notifications', type: :request do
    describe '(GET: /api/v0/user/notifications)' do
      context 'valid inputs' do
        it 'returns [204 No Content] for empty notifications' do
          headers = { 'Authorization' => "Bearer #{@valid_access_token}" }
          get('/api/v0/user/notifications', headers:)
          expect(response).to have_http_status(200)
        end
        it 'returns [200 OK]' do
          headers = { 'Authorization' => "Bearer #{@valid_access_token}" }
          get('/api/v0/user/notifications', headers:)
          expect(response).to have_http_status(200)
        end
      end

      context 'invalid inputs' do
        it 'returns [400 Bad Request] for missing authentication' do
          headers = { 'Content-Type' => 'application/json' }
          get('/api/v0/user/notifications', headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [401 Unauthorized] for expired/invalid access token' do
          headers = { 'Authorization' => "Bearer #{@invalid_access_token}" }
          get('/api/v0/user/notifications', headers:)
          expect(response).to have_http_status(401)
        end
        it 'returns [403 Forbidden] for blacklisted user' do
          headers = { 'Authorization' => "Bearer #{@valid_at_blacklisted}" }
          get('/api/v0/user/notifications', headers:)
          expect(response).to have_http_status(403)
        end
      end
    end
  end

  describe 'Get unread application notifications', type: :request do
    describe '(GET: /api/v0/user/notifications/unread)' do
      context 'valid inputs' do
        it 'returns [204 No Content] for empty notifications' do
          headers = { 'Authorization' => "Bearer #{@valid_access_token}" }
          get('/api/v0/user/notifications', headers:)
          expect(response).to have_http_status(200)
        end
        it 'returns [200 OK]' do
          headers = { 'Authorization' => "Bearer #{@valid_access_token}" }
          get('/api/v0/user/notifications/unread', headers:)
          expect(response).to have_http_status(200)
        end
      end

      context 'invalid inputs' do
        it 'returns [400 Bad Request] for missing authentication' do
          headers = { 'Content-Type' => 'application/json' }
          get('/api/v0/user/notifications/unread', headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [401 Unauthorized] for expired/invalid access token' do
          headers = { 'Authorization' => "Bearer #{@invalid_access_token}" }
          get('/api/v0/user/notifications/unread', headers:)
          expect(response).to have_http_status(401)
        end
        it 'returns [403 Forbidden] for blacklisted user' do
          headers = { 'Authorization' => "Bearer #{@valid_at_blacklisted}" }
          get('/api/v0/user/notifications/unread', headers:)
          expect(response).to have_http_status(403)
        end
      end
    end
  end

  describe '(PATCH: /api/v0/user/notifications)' do
    context 'valid normal inputs' do
      it 'returns [200 Ok]' do
        headers = { 'Authorization' => "Bearer #{@valid_access_token}" }
        patch("/api/v0/user/notifications/#{@notification.id.to_i}?read=1", headers:)
        expect(response).to have_http_status(200)
      end
      it 'returns [200 Ok]' do
        headers = { 'Authorization' => "Bearer #{@valid_access_token}" }
        patch("/api/v0/user/notifications/#{@notification.id.to_i}?read=1", headers:)
        expect(response).to have_http_status(200)
      end
    end
    context 'invalid inputs' do
      it 'returns [400 Bad Request] for missing access token in header' do
        patch("/api/v0/user/notifications/#{@notification.id.to_i}?read=1")
        expect(response).to have_http_status(400)
      end
      it 'returns [401 Unauthorized] for missing notification ID' do
        headers = { 'Authorization' => "Bearer #{@valid_access_token}" }
        patch('/api/v0/user/notifications', headers:)
        expect(response).to have_http_status(400)
      end
      it 'returns [401 Unauthorized] for expired/invalid access token' do
        headers = { 'Authorization' => "Bearer #{@invalid_access_token}" }
        patch("/api/v0/user/notifications/#{@notification.id.to_i}?read=1", headers:)
        expect(response).to have_http_status(401)
      end
      it 'returns [403 Forbidden] for not own notification' do
        headers = { 'Authorization' => "Bearer #{@valid_access_token}" }
        patch("/api/v0/user/notifications/#{@not_owned_notification.id.to_i}?read=1", headers:)
        expect(response).to have_http_status(403)
      end
      it 'returns [403 Forbidden] for blacklisted user' do
        headers = { 'Authorization' => "Bearer #{@valid_at_blacklisted}" }
        patch("/api/v0/user/notifications/#{@blacklisted_notification.id.to_i}?read=1", headers:)
        expect(response).to have_http_status(403)
      end
    end
  end
end
