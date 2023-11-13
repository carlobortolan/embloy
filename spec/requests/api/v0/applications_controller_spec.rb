# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'ApplicationsController' do
  before(:all) do
    charset = ('a'..'z').to_a + ('A'..'Z').to_a

    ### USER CREATION ###

    # Create valid verified user without jobs, applications, ...
    @valid_user = User.create!(
      "first_name": "Max",
      "last_name": "Mustermann",
      "email": "#{(0...16).map { charset.sample }.join}@embloy.com",
      "password": "password",
      "password_confirmation": "password",
      "user_role": "verified",
      "activity_status": "1"
    )
    puts "Created verified user without jobs, applications: #{@valid_user.id}"

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

    # Create valid verified user with applications
    @valid_user_has_applications = User.create!(
      "first_name": "Max",
      "last_name": "Mustermann",
      "email": "#{(0...16).map { charset.sample }.join}@embloy.com",
      "password": "password",
      "password_confirmation": "password",
      "user_role": "verified",
      "activity_status": "1"
    )
    puts "Created valid verified user with applications: #{@valid_user_has_applications.id}"

    ### ACCESS / REFRESH TOKENS ###

    # Verified user refresh/access tokens
    credentials = Base64.strict_encode64("#{@valid_user.email}:password")
    headers = { 'Authorization' => "Basic #{credentials}" }
    post '/api/v0/user/auth/token/refresh', headers: headers
    @valid_refresh_token = JSON.parse(response.body)['refresh_token']
    puts "Valid user refresh token: #{@valid_refresh_token}"

    headers = { "HTTP_REFRESH_TOKEN" => @valid_refresh_token }
    post '/api/v0/user/auth/token/access', headers: headers
    @valid_access_token = JSON.parse(response.body)['access_token']
    puts "Valid user access token: #{@valid_access_token}"

    # Valid user with own jobs refresh/access tokens
    credentials = Base64.strict_encode64("#{@valid_user_has_own_jobs.email}:password")
    headers = { 'Authorization' => "Basic #{credentials}" }
    post '/api/v0/user/auth/token/refresh', headers: headers
    @valid_rt_has_own_jobs = JSON.parse(response.body)['refresh_token']
    puts "Valid user with own jobs refresh token: #{@valid_rt_has_own_jobs}"

    headers = { "HTTP_REFRESH_TOKEN" => @valid_rt_has_own_jobs }
    post '/api/v0/user/auth/token/access', headers: headers
    @valid_at_has_own_jobs = JSON.parse(response.body)['access_token']
    puts "Valid user with own jobs access token: #{@valid_at_has_own_jobs}"

    # Valid user with upcoming jobs refresh/access tokens
    credentials = Base64.strict_encode64("#{@valid_user_has_applications.email}:password")
    headers = { 'Authorization' => "Basic #{credentials}" }
    post '/api/v0/user/auth/token/refresh', headers: headers
    @valid_rt_has_applications = JSON.parse(response.body)['refresh_token']
    puts "Valid user with upcoming jobs refresh token: #{@valid_rt_has_applications}"

    headers = { "HTTP_REFRESH_TOKEN" => @valid_rt_has_applications }
    post '/api/v0/user/auth/token/access', headers: headers
    @valid_at_has_applications = JSON.parse(response.body)['access_token']
    puts "Valid user with own jobs access token: #{@valid_at_has_applications}"

    # Invalid/expired access tokens
    @invalid_access_token = "eyJhbGciOiJIUzI1NiJ9.eyJzdWILOjQ6LCJleHAiOjE2OTgxNzk0MjgsImp0aSI6IjQ1NDMyZWUyNWE4YWUyMjc1ZGY0YTE2ZTNlNmQ0YTY4IiwiaWF0IjoxNjk4MTY1MDI4LCJpc3MiOiJDQl9TdXJmYWNlUHJvOCJ9.nqGgQ6Z52CbaHZzPGcwQG6U-nMDxb1yIe7HQMxjoDTs"

    # OWN JOBS & UPCOMING JOBS
    # Create own jobs for valid verified user (valid_user_has_own_jobs) and upcoming jobs for valid verified user (valid_user_has_upcoming_jobs)
    cv_required = [false, true, true, true, true, false]
    allowed_cv_formats = [%w[.pdf .docx .txt .xml], [".pdf"], [".docx"], [".txt"], ["xml"], %w[.pdf .docx .txt .xml]]
    @jobs = []
    @applications = []
    6.times do |i|
      @jobs << Job.create!(
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
        job_type_value: "1",
        cv_required: cv_required[i],
        allowed_cv_format: allowed_cv_formats[i]
      )
      puts "Created new job for: #{@valid_user_has_own_jobs.id}"
    end
    5.times do |i|
      @applications << Application.create!(
        user_id: @valid_user_has_applications.id,
        job_id: @jobs[i].id,
        application_text: "TestUpcomingApplicationText",
        response: "No response yet ..."
      )
      puts "#{@valid_user_has_applications.id} applied to #{@jobs[i].id}"
    end
  end

  describe "Applications", type: :request do

    describe "(GET: /api/v0/jobs/{id}/applications)" do
      context 'valid normal inputs' do
        it 'returns [200 Ok] and JSON job JSONs if job has applications' do
          headers = { "HTTP_ACCESS_TOKEN" => @valid_at_has_own_jobs }
          5.times do |i|
            get "/api/v0/jobs/#{@jobs[i].id}/applications", headers: headers
            expect(response).to have_http_status(200)
          end
        end
        it 'returns [204 No Content] if job does not have any applications' do
          headers = { "HTTP_ACCESS_TOKEN" => @valid_at_has_own_jobs }
          get "/api/v0/jobs/#{@jobs[5].id}/applications", headers: headers
          expect(response).to have_http_status(204)
        end
      end
      context 'invalid inputs' do
        it 'returns [400 Bad Request] for missing access token in header' do
          get "/api/v0/jobs/#{@jobs[5].id}/applications"
          expect(response).to have_http_status(400)
        end
        it 'returns [401 Unauthorized] for expired/invalid access token' do
          headers = { "HTTP_ACCESS_TOKEN" => @invalid_access_token }
          get "/api/v0/jobs/#{@jobs[5].id}/applications", headers: headers
          expect(response).to have_http_status(401)
        end
        it 'returns [403 Forbidden] if user is not owner' do
          headers = { "HTTP_ACCESS_TOKEN" => @valid_access_token }
          get "/api/v0/jobs/#{@jobs[5].id}/applications", headers: headers
          expect(response).to have_http_status(403)
        end
        it 'returns [404 Not Found] if job does not exist' do
          headers = { "HTTP_ACCESS_TOKEN" => @valid_access_token }
          get "/api/v0/jobs/131231231231231312312/applications", headers: headers
          expect(response).to have_http_status(404)
        end
      end
    end

    describe "(GET: /api/v0/jobs/{id}/application)" do
      context 'valid normal inputs' do
        it 'returns [200 Ok] and JSON job JSONs if job has applications' do
          headers = { "HTTP_ACCESS_TOKEN" => @valid_at_has_applications }
          5.times do |i|
            get "/api/v0/jobs/#{@jobs[i].id}/application", headers: headers
            expect(response).to have_http_status(200)
          end
        end
        it 'returns [204 No Content] if job does not have any applications' do
          headers = { "HTTP_ACCESS_TOKEN" => @valid_at_has_applications }
          get "/api/v0/jobs/#{@jobs[5].id}/application", headers: headers
          expect(response).to have_http_status(204)
        end
        it 'returns [204 No Content] if user is has not submitted an application' do
          headers = { "HTTP_ACCESS_TOKEN" => @valid_access_token }
          get "/api/v0/jobs/#{@jobs[5].id}/application", headers: headers
          expect(response).to have_http_status(204)
          headers = { "HTTP_ACCESS_TOKEN" => @valid_at_has_own_jobs }
          get "/api/v0/jobs/#{@jobs[5].id}/application", headers: headers
          expect(response).to have_http_status(204)
        end
      end
      context 'invalid inputs' do
        it 'returns [400 Bad Request] for missing access token in header' do
          get "/api/v0/jobs/#{@jobs[5].id}/application"
          expect(response).to have_http_status(400)
        end
        it 'returns [401 Unauthorized] for expired/invalid access token' do
          headers = { "HTTP_ACCESS_TOKEN" => @invalid_access_token }
          get "/api/v0/jobs/#{@jobs[5].id}/application", headers: headers
          expect(response).to have_http_status(401)
        end
        it 'returns [404 Not Found] if job does not exist' do
          headers = { "HTTP_ACCESS_TOKEN" => @valid_at_has_applications }
          get "/api/v0/jobs/131231231231231312312/application", headers: headers
          expect(response).to have_http_status(404)
        end
      end
    end
    # TODO
    describe "(PATCH: /api/v0/jobs/{id}/applications/{id}/accept)" do
      context 'valid normal inputs' do
        it 'returns [200 Ok] and accepts application' do
          headers = { "HTTP_ACCESS_TOKEN" => @valid_at_has_own_jobs }
          5.times do |i|
            patch "/api/v0/jobs/#{@jobs[i].id}/applications/#{@valid_user_has_applications.id}/accept", headers: headers
            expect(response).to have_http_status(200)
          end
        end
        it 'returns [404 Not found] if job does not have any applications' do
          headers = { "HTTP_ACCESS_TOKEN" => @valid_at_has_own_jobs }
          patch "/api/v0/jobs/#{@jobs[5].id}/applications/#{@valid_user_has_applications.id}/accept", headers: headers
          expect(response).to have_http_status(404)
        end
      end
      context 'invalid inputs' do
        it 'returns [400 Bad Request] for missing access token in header' do
          patch "/api/v0/jobs/#{@jobs[0].id}/applications/#{@valid_user_has_applications.id}/accept"
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] if application already accepted' do
          headers = { "HTTP_ACCESS_TOKEN" => @valid_at_has_own_jobs }
          @applications[0].accept("Accepted")
          patch "/api/v0/jobs/#{@jobs[0].id}/applications/#{@valid_user_has_applications.id}/accept", headers: headers
          @applications[0].reject("Rejected")
          expect(response).to have_http_status(400)
        end
        it 'returns [401 Unauthorized] for expired/invalid access token' do
          headers = { "HTTP_ACCESS_TOKEN" => @invalid_access_token }
          patch "/api/v0/jobs/#{@jobs[0].id}/applications/#{@valid_user_has_applications.id}/accept", headers: headers
          expect(response).to have_http_status(401)
        end
        it 'returns [403 Forbidden] if user is not owner' do
          headers = { "HTTP_ACCESS_TOKEN" => @valid_access_token }
          patch "/api/v0/jobs/#{@jobs[0].id}/applications/#{@valid_user_has_applications.id}/accept", headers: headers
          expect(response).to have_http_status(403)
        end
        it 'returns [404 Not Found] if job does not exist' do
          headers = { "HTTP_ACCESS_TOKEN" => @valid_access_token }
          patch "/api/v0/jobs/123123123/applications/#{@valid_user_has_applications.id}/accept", headers: headers
          expect(response).to have_http_status(404)
        end
        it 'returns [404 Not Found] if application does not exist' do
          headers = { "HTTP_ACCESS_TOKEN" => @valid_at_has_own_jobs }
          patch "/api/v0/jobs/#{@jobs[0].id}/applications/123123123123123123132/accept", headers: headers
          expect(response).to have_http_status(404)
        end
      end
    end
    # TODO
    describe "(PATCH: /api/v0/jobs/{id}/applications/{id}/reject)" do
      context 'valid normal inputs' do
        it 'returns [200 Ok] and rejects application' do
          headers = { "HTTP_ACCESS_TOKEN" => @valid_at_has_own_jobs }
          5.times do |i|
            patch "/api/v0/jobs/#{@jobs[i].id}/applications/#{@valid_user_has_applications.id}/reject", headers: headers
            expect(response).to have_http_status(200)
          end
        end
        it 'returns [404 Not found] if job does not have any applications' do
          headers = { "HTTP_ACCESS_TOKEN" => @valid_at_has_own_jobs }
          patch "/api/v0/jobs/#{@jobs[5].id}/applications/#{@valid_user_has_applications.id}/reject", headers: headers
          expect(response).to have_http_status(404)
        end
      end
      context 'invalid inputs' do
        it 'returns [400 Bad Request] for missing access token in header' do
          patch "/api/v0/jobs/#{@jobs[0].id}/applications/#{@valid_user_has_applications.id}/reject"
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] if application already rejected' do
          headers = { "HTTP_ACCESS_TOKEN" => @valid_at_has_own_jobs }
          @applications[0].reject("Accepted")
          patch "/api/v0/jobs/#{@jobs[0].id}/applications/#{@valid_user_has_applications.id}/reject", headers: headers
          @applications[0].accept("Rejected")
          expect(response).to have_http_status(400)
        end
        it 'returns [401 Unauthorized] for expired/invalid access token' do
          headers = { "HTTP_ACCESS_TOKEN" => @invalid_access_token }
          patch "/api/v0/jobs/#{@jobs[0].id}/applications/#{@valid_user_has_applications.id}/reject", headers: headers
          expect(response).to have_http_status(401)
        end
        it 'returns [403 Forbidden] if user is not owner' do
          headers = { "HTTP_ACCESS_TOKEN" => @valid_access_token }
          patch "/api/v0/jobs/#{@jobs[0].id}/applications/#{@valid_user_has_applications.id}/reject", headers: headers
          expect(response).to have_http_status(403)
        end
        it 'returns [404 Not Found] if job does not exist' do
          headers = { "HTTP_ACCESS_TOKEN" => @valid_access_token }
          patch "/api/v0/jobs/123123123/applications/#{@valid_user_has_applications.id}/reject", headers: headers
          expect(response).to have_http_status(404)
        end
        it 'returns [404 Not Found] if application does not exist' do
          headers = { "HTTP_ACCESS_TOKEN" => @valid_at_has_own_jobs }
          patch "/api/v0/jobs/#{@jobs[0].id}/applications/123123123123123123132/reject", headers: headers
          expect(response).to have_http_status(404)
        end
      end
    end
    # TODO
    describe "(POST: /api/v0/jobs/{id}/applications)" do
    end
  end
end