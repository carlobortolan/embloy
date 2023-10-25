# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'JobsController' do
  before(:all) do
    # Create basic user
    charset = ('a'..'z').to_a + ('A'..'Z').to_a
    @valid_user = User.create!(
      "first_name": "Max",
      "last_name": "Mustermann",
      "email": "#{(0...16).map { charset.sample }.join}@embloy.com",
      "password": "password",
      "password_confirmation": "password",
      "user_role": "verified",
      "activity_status": "1"
    )
    puts "Created valid user: #{@valid_user.id}"

    # Fetch tokens
    credentials = Base64.strict_encode64("#{@valid_user.email}:password")
    headers = { 'Authorization' => "Basic #{credentials}" }
    post '/api/v0/user/auth/token/refresh', headers: headers
    @valid_rt = JSON.parse(response.body)['refresh_token']
    puts "Valid user with upcoming jobs refresh token: #{@valid_rt}"

    headers = { "HTTP_REFRESH_TOKEN" => @valid_rt }
    post '/api/v0/user/auth/token/access', headers: headers
    @valid_at = JSON.parse(response.body)['access_token']
    puts "Valid user with own jobs access token: #{@valid_at}"

    @invalid_access_token = "eyJhbGciOiJIUzI1NiJ9.eyJzdWILOjQ5LCJleHAiOjE2OTgxNzk0MjgsImp0aSI6IjQ1NDMyZWUyNWE4YWUyMjc1ZGY0YTE2ZTNlNmQ0YTY4IiwiaWF0IjoxNjk4MTY1MDI4LCJpc3MiOiJDQl9TdXJmYWNlUHJvOCJ9.nqGgQ6Z52CbaHZzPGcwQG6U-nMDxb1yIe7HQMxjoDTs"

    # Create jobs
    5.times do
      @job = Job.create!(
        user_id: @valid_user.id,
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
      puts "Created new job for: #{@valid_user.id}"
    end
  end

  describe "Job", type: :request do
    describe "(GET: /api/v0/jobs/{id})" do
      context 'valid normal inputs' do
        it 'returns [200 Ok] and job JSONs if job exists' do
          headers = { "HTTP_ACCESS_TOKEN" => @valid_at }
          get "/api/v0/jobs/#{@job.id}", headers: headers
          expect(response).to have_http_status(200)
        end
        it 'returns [204 No Content] if job does not exist' do
          headers = { "HTTP_ACCESS_TOKEN" => @valid_at }
          get '/api/v0/jobs/123123123123123123123123', headers: headers
          expect(response).to have_http_status(404)
        end
      end
      context 'invalid inputs' do
        it 'returns [400 Bad Request] for missing access token in header' do
          get "/api/v0/jobs/#{@job.id}"
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for malformed query params' do
          headers = { "HTTP_ACCESS_TOKEN" => @valid_at }
          get "/api/v0/jobs/-1", headers: headers
          expect(response).to have_http_status(400)
          get "/api/v0/jobs/abc", headers: headers
          expect(response).to have_http_status(400)
        end
        it 'returns [401 Unauthorized] for expired/invalid access token' do
          headers = { "HTTP_ACCESS_TOKEN" => @invalid_access_token }
          get "/api/v0/jobs/#{@job.id}", headers: headers
          expect(response).to have_http_status(401)
        end
      end
    end

    describe "(GET: /api/v0/find)" do
      context 'valid normal inputs' do
        it 'returns [200 Ok] and job JSONs if job exists' do
          headers = { "HTTP_ACCESS_TOKEN" => @valid_at }
          get "/api/v0/find?query=TestJob&job_type=Retail&sort_by=date_desc", headers: headers
          expect(response).to have_http_status(200)
        end
        it 'returns [200 Ok] and job JSONs if query blank' do
          headers = { "HTTP_ACCESS_TOKEN" => @valid_at }
          get "/api/v0/find?job_type=Retail&sort_by=date_desc", headers: headers
          expect(response).to have_http_status(200)
        end
        it 'returns [200 Ok] and job JSONs if job_type blank' do
          headers = { "HTTP_ACCESS_TOKEN" => @valid_at }
          get "/api/v0/find?query=TestJob&sort_by=date_desc", headers: headers
          expect(response).to have_http_status(200)
        end
        it 'returns [200 Ok] and job JSONs if sort_by blank' do
          headers = { "HTTP_ACCESS_TOKEN" => @valid_at }
          get "/api/v0/find?query=TestJob&job_type=Retail", headers: headers
          expect(response).to have_http_status(200)
        end
        it 'returns [200 Ok] and job JSONs if params blank' do
          headers = { "HTTP_ACCESS_TOKEN" => @valid_at }
          get "/api/v0/find", headers: headers
          expect(response).to have_http_status(200)
        end
        it 'returns [204 No Content] if no matching jobs exist' do
          headers = { "HTTP_ACCESS_TOKEN" => @valid_at }
          get "/api/v0/find?query=123&job_type=Food&sort_by=date_desc", headers: headers
          expect(response).to have_http_status(204)
        end
        it 'returns [204 No Content] for wrong job_type in params' do
          headers = { "HTTP_ACCESS_TOKEN" => @valid_at }
          get "/api/v0/find?job_type=test", headers: headers
          expect(response).to have_http_status(204)
        end
        it 'returns [204 No Content] for wrong sort_by in params' do
          headers = { "HTTP_ACCESS_TOKEN" => @valid_at }
          get "/api/v0/find?sort_by=test", headers: headers
          expect(response).to have_http_status(204)
        end
      end
      context 'invalid inputs' do
        it 'returns [400 Bad Request] for missing access token in header' do
          headers = { "HTTP_ACCESS_TOKEN" => @valid_at }
          get "/api/v0/find?query=123&job_type=Food&sort_by=date_desc"
          expect(response).to have_http_status(400)
        end
        it 'returns [401 Unauthorized] for expired/invalid access token' do
          headers = { "HTTP_ACCESS_TOKEN" => @invalid_access_token }
          get "/api/v0/find?query=123&job_type=Food&sort_by=date_desc", headers: headers
          expect(response).to have_http_status(401)
        end
      end
    end

    describe "(POST: /api/v0/maps)" do
      context 'valid normal inputs' do
        it 'returns [200 Ok] and job JSONs if job exists' do
          headers = { "HTTP_ACCESS_TOKEN" => @valid_at }
          get "/api/v0/maps?longitude=0&latitude=0", headers: headers
          expect(response).to have_http_status(200)
        end
        it 'returns [204 No Content] if job does not exist' do
          Job.delete_all
          headers = { "HTTP_ACCESS_TOKEN" => @valid_at }
          get "/api/v0/maps?longitude=0&latitude=0", headers: headers
          expect(response).to have_http_status(204)
        end
      end
      context 'invalid inputs' do
        it 'returns [400 Bad Request] for missing access token in header' do
          get "/api/v0/maps?longitude=0&latitude=0", headers: headers
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for malformed query params' do
          headers = { "HTTP_ACCESS_TOKEN" => @valid_at }
          get "/api/v0/maps?longitude=180.1&latitude=0", headers: headers
          expect(response).to have_http_status(400)
          get "/api/v0/maps?longitude=0&latitude=90.1", headers: headers
          expect(response).to have_http_status(400)
          get "/api/v0/maps?longitude=-180.1&latitude=0", headers: headers
          expect(response).to have_http_status(400)
          get "/api/v0/maps?longitude=0&latitude=-90.1", headers: headers
          expect(response).to have_http_status(400)
          get "/api/v0/maps?longitude=0", headers: headers
          expect(response).to have_http_status(400)
          get "/api/v0/maps?latitude=-1", headers: headers
          expect(response).to have_http_status(400)
          get "/api/v0/maps", headers: headers
          expect(response).to have_http_status(400)
        end
        it 'returns [401 Unauthorized] for expired/invalid access token' do
          headers = { "HTTP_ACCESS_TOKEN" => @invalid_access_token }
          get "/api/v0/maps?longitude=0&latitude=0", headers: headers
          expect(response).to have_http_status(401)
        end
      end
    end

    describe "(POST: /api/v0/jobs)" do
      # TODO
    end

    describe "(PATCH: /api/v0/jobs)" do
      # TODO
    end
  end
end