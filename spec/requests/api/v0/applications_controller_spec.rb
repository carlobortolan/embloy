# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'ApplicationsController' do
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
      activity_status: '1'
    )
    puts "Created verified user without jobs, applications: #{@valid_user.id}"

    # Create valid verified user with own jobs
    @valid_user_has_own_jobs = User.create!(
      first_name: 'Max',
      last_name: 'Mustermann',
      email: "#{(0...16).map { charset.sample }.join}@embloy.com",
      password: 'password',
      password_confirmation: 'password',
      user_role: 'verified',
      activity_status: '1'
    )
    puts "Created valid verified user with own jobs: #{@valid_user_has_own_jobs.id}"

    # Create valid verified user with applications
    @valid_user_has_applications = User.create!(
      first_name: 'Max',
      last_name: 'Mustermann',
      email: "#{(0...16).map { charset.sample }.join}@embloy.com",
      password: 'password',
      password_confirmation: 'password',
      user_role: 'verified',
      activity_status: '1'
    )
    puts "Created valid verified user with applications: #{@valid_user_has_applications.id}"

    # Create valid verified user who will apply for jobs
    @valid_applicant = User.create!(
      first_name: 'Max',
      last_name: 'Mustermann',
      email: "#{(0...16).map { charset.sample }.join}@embloy.com",
      password: 'password',
      password_confirmation: 'password',
      user_role: 'verified',
      activity_status: '1'
    )
    puts "Created valid verified user with applications: #{@valid_applicant.id}"

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
    post('/api/v0/auth/token/refresh', headers:)
    @valid_refresh_token = JSON.parse(response.body)['refresh_token']
    puts "Valid user refresh token: #{@valid_refresh_token}"

    headers = { 'HTTP_REFRESH_TOKEN' => @valid_refresh_token }
    post('/api/v0/auth/token/access', headers:)
    @valid_access_token = JSON.parse(response.body)['access_token']
    puts "Valid user access token: #{@valid_access_token}"

    # Valid user with own jobs refresh/access tokens
    credentials = Base64.strict_encode64("#{@valid_user_has_own_jobs.email}:password")
    headers = { 'Authorization' => "Basic #{credentials}" }
    post('/api/v0/auth/token/refresh', headers:)
    @valid_rt_has_own_jobs = JSON.parse(response.body)['refresh_token']
    puts "Valid user with own jobs refresh token: #{@valid_rt_has_own_jobs}"

    headers = { 'HTTP_REFRESH_TOKEN' => @valid_rt_has_own_jobs }
    post('/api/v0/auth/token/access', headers:)
    @valid_at_has_own_jobs = JSON.parse(response.body)['access_token']
    puts "Valid user with own jobs access token: #{@valid_at_has_own_jobs}"

    # Valid user with upcoming jobs refresh/access tokens
    credentials = Base64.strict_encode64("#{@valid_user_has_applications.email}:password")
    headers = { 'Authorization' => "Basic #{credentials}" }
    post('/api/v0/auth/token/refresh', headers:)
    @valid_rt_has_applications = JSON.parse(response.body)['refresh_token']
    puts "Valid user with upcoming jobs refresh token: #{@valid_rt_has_applications}"

    headers = { 'HTTP_REFRESH_TOKEN' => @valid_rt_has_applications }
    post('/api/v0/auth/token/access', headers:)
    @valid_at_has_applications = JSON.parse(response.body)['access_token']
    puts "Valid user with own jobs access token: #{@valid_at_has_applications}"

    # Valid user who will apply for jobs refresh/access tokens
    credentials = Base64.strict_encode64("#{@valid_applicant.email}:password")
    headers = { 'Authorization' => "Basic #{credentials}" }
    post('/api/v0/auth/token/refresh', headers:)
    @valid_rt_applicant = JSON.parse(response.body)['refresh_token']
    puts "Valid user with upcoming jobs refresh token: #{@valid_rt_applicant}"

    headers = { 'HTTP_REFRESH_TOKEN' => @valid_rt_applicant }
    post('/api/v0/auth/token/access', headers:)
    @valid_at_applicant = JSON.parse(response.body)['access_token']
    puts "Valid user with own jobs access token: #{@valid_at_applicant}"

    # Blacklisted user refresh/access tokens
    credentials = Base64.strict_encode64("#{@blacklisted_user.email}:password")
    headers = { 'Authorization' => "Basic #{credentials}" }
    post('/api/v0/auth/token/refresh', headers:)
    @valid_rt_blacklisted = JSON.parse(response.body)['refresh_token']
    puts "Valid user who will be blacklisted refresh token: #{@valid_rt_blacklisted}"

    headers = { 'HTTP_REFRESH_TOKEN' => @valid_rt_blacklisted }
    post('/api/v0/auth/token/access', headers:)
    @valid_at_blacklisted = JSON.parse(response.body)['access_token']
    puts "Valid user who will be blacklisted access token: #{@valid_at_blacklisted}"

    UserBlacklist.create!(
      user_id: @blacklisted_user.id,
      reason: 'Test blacklist'
    )
    puts "Blacklisted user #{@blacklisted_user.id}}"

    # Invalid/expired access tokens
    @invalid_access_token = 'eyJhbGciOiJIUzI1NiJ9.eyJzdWILOjQ6LCJleHAiOjE2OTgxNzk0MjgsImp0aSI6IjQ1NDMyZWUyNWE4YWUyMjc1ZGY0YTE2ZTNlNmQ0YTY4IiwiaWF0IjoxNjk4MTY1MDI4LCJpc3MiOiJDQl9TdXJmYWNlUHJvOCJ9.nqGgQ6Z52CbaHZzPGcwQG6U-nMDxb1yIe7HQMxjoDTs'

    # OWN JOBS & UPCOMING JOBS
    # Create own jobs for valid verified user (valid_user_has_own_jobs) and upcoming jobs for valid verified user (valid_user_has_upcoming_jobs)
    cv_required = [false, true, true, true, true, true, true, true, true]
    allowed_cv_formats = [['.pdf', '.docx', '.txt', '.xml'], ['.pdf'], ['.docx'], ['.txt'], ['.xml'], ['.pdf'], ['.docx'], ['.txt'], ['.xml']]
    @jobs = []
    @applications = []
    9.times do |i|
      @jobs << Job.create!(
        user_id: @valid_user_has_own_jobs.id,
        title: 'TestJob',
        description: 'TestDescription',
        longitude: '0.0',
        latitude: '0.0',
        position: 'Intern',
        salary: '123',
        start_slot: Time.now + 1.year,
        key_skills: 'Entrepreneurship',
        duration: '14',
        currency: 'CHF',
        job_type: 'Retail',
        job_type_value: '1',
        cv_required: cv_required[i],
        allowed_cv_formats: allowed_cv_formats[i]
      )
      puts "Created new job for: #{@valid_user_has_own_jobs.id}"
    end
    6.times do |i|
      @applications << Application.create!(
        user_id: @valid_user_has_applications.id,
        job_id: @jobs[i].id,
        application_text: 'TestUpcomingApplicationText',
        response: 'No response yet ...'
      )
      puts "#{@valid_user_has_applications.id} applied to #{@jobs[i].id}"
    end
  end

  describe 'Applications', type: :request do
    describe '(GET: /api/v0/jobs/{id}/applications)' do
      context 'valid normal inputs' do
        it 'returns [200 Ok] and JSON application JSONs if job has applications' do
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_at_has_own_jobs }
          5.times do |i|
            get("/api/v0/jobs/#{@jobs[i].id}/applications", headers:)
            expect(response).to have_http_status(200)
          end
        end
        it 'returns [204 No Content] if job does not have any applications' do
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_at_has_own_jobs }
          get("/api/v0/jobs/#{@jobs[6].id}/applications", headers:)
          expect(response).to have_http_status(204)
        end
      end
      context 'invalid inputs' do
        it 'returns [400 Bad Request] for missing access token in header' do
          get "/api/v0/jobs/#{@jobs[6].id}/applications"
          expect(response).to have_http_status(400)
        end
        it 'returns [401 Unauthorized] for expired/invalid access token' do
          headers = { 'HTTP_ACCESS_TOKEN' => @invalid_access_token }
          get("/api/v0/jobs/#{@jobs[6].id}/applications", headers:)
          expect(response).to have_http_status(401)
        end
        it 'returns [403 Forbidden] if user is not owner' do
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_access_token }
          get("/api/v0/jobs/#{@jobs[6].id}/applications", headers:)
          expect(response).to have_http_status(403)
        end
        it 'returns [403 Forbidden] for blacklisted user' do
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_at_blacklisted }
          get("/api/v0/jobs/#{@jobs[6].id}/applications", headers:)
          expect(response).to have_http_status(403)
        end
        it 'returns [404 Not Found] if job does not exist' do
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_access_token }
          get('/api/v0/jobs/131231231231231312312/applications', headers:)
          expect(response).to have_http_status(404)
        end
      end
    end

    describe '(GET: /api/v0/jobs/{id}/application)' do
      context 'valid normal inputs' do
        it 'returns [200 Ok] and JSON application JSONs if job has applications' do
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_at_has_applications }
          5.times do |i|
            get("/api/v0/jobs/#{@jobs[i].id}/application", headers:)
            expect(response).to have_http_status(200)
          end
        end
        it 'returns [204 No Content] if job does not have any applications' do
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_at_has_applications }
          get("/api/v0/jobs/#{@jobs[6].id}/application", headers:)
          expect(response).to have_http_status(204)
        end
        it 'returns [204 No Content] if user is has not submitted an application' do
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_access_token }
          get("/api/v0/jobs/#{@jobs[6].id}/application", headers:)
          expect(response).to have_http_status(204)
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_at_has_own_jobs }
          get("/api/v0/jobs/#{@jobs[6].id}/application", headers:)
          expect(response).to have_http_status(204)
        end
      end
      context 'invalid inputs' do
        it 'returns [400 Bad Request] for missing access token in header' do
          get "/api/v0/jobs/#{@jobs[6].id}/application"
          expect(response).to have_http_status(400)
        end
        it 'returns [401 Unauthorized] for expired/invalid access token' do
          headers = { 'HTTP_ACCESS_TOKEN' => @invalid_access_token }
          get("/api/v0/jobs/#{@jobs[6].id}/application", headers:)
          expect(response).to have_http_status(401)
        end
        it 'returns [403 Forbidden] for blacklisted user' do
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_at_blacklisted }
          get("/api/v0/jobs/#{@jobs[6].id}/application", headers:)
          expect(response).to have_http_status(403)
        end
        it 'returns [404 Not Found] if job does not exist' do
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_at_has_applications }
          get('/api/v0/jobs/131231231231231312312/application', headers:)
          expect(response).to have_http_status(404)
        end
      end
    end

    describe '(PATCH: /api/v0/jobs/{id}/applications/{id}/accept)' do
      context 'valid normal inputs' do
        it 'returns [200 Ok] and accepts application' do
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_at_has_own_jobs }
          5.times do |i|
            patch("/api/v0/jobs/#{@jobs[i].id}/applications/#{@valid_user_has_applications.id}/accept", headers:)
            expect(response).to have_http_status(200)
          end
        end
        it 'returns [200 Ok] and accepts application with response' do
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_at_has_own_jobs }
          message = 'Good job!'
          patch("/api/v0/jobs/#{@jobs[5].id}/applications/#{@valid_user_has_applications.id}/accept?response=#{message}", headers:)
          expect(response).to have_http_status(200)
        end
        it 'returns [404 Not found] if job does not have any applications' do
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_at_has_own_jobs }
          patch("/api/v0/jobs/#{@jobs[6].id}/applications/#{@valid_user_has_applications.id}/accept", headers:)
          expect(response).to have_http_status(404)
        end
      end
      context 'invalid inputs' do
        it 'returns [400 Bad Request] for missing access token in header' do
          patch "/api/v0/jobs/#{@jobs[0].id}/applications/#{@valid_user_has_applications.id}/accept"
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] if application already accepted' do
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_at_has_own_jobs }
          @applications[0].accept('Accepted')
          patch("/api/v0/jobs/#{@jobs[0].id}/applications/#{@valid_user_has_applications.id}/accept", headers:)
          @applications[0].reject('Rejected')
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] and if response message is too long' do
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_at_has_own_jobs }
          message = 'Lorem ipsum venenatis quis sollicitudin elit eros aliquam scelerisque ornare tortor volutpat, quisque ultricies tortor euismod venenatis inceptos quis feugiat condimentum. Bibendum etiam hendrerit pretium odio sit lectus dui congue hendrerit dolor sit, consectetur ante dapibus vitae mi dictumst velit lacus fermentum fames dictum laoreet, nibh tristique quisque aenean mi sociosqu justo rutrum dictum odio. Porttitor turpis hendrerit consequat habitant enim ante urna dictumst convallis ligula massa pharetra'
          patch("/api/v0/jobs/#{@jobs[5].id}/applications/#{@valid_user_has_applications.id}/accept?response=#{message}", headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [401 Unauthorized] for expired/invalid access token' do
          headers = { 'HTTP_ACCESS_TOKEN' => @invalid_access_token }
          patch("/api/v0/jobs/#{@jobs[0].id}/applications/#{@valid_user_has_applications.id}/accept", headers:)
          expect(response).to have_http_status(401)
        end
        it 'returns [403 Forbidden] if user is not owner' do
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_access_token }
          patch("/api/v0/jobs/#{@jobs[0].id}/applications/#{@valid_user_has_applications.id}/accept", headers:)
          expect(response).to have_http_status(403)
        end
        it 'returns [403 Forbidden] for blacklisted user' do
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_at_blacklisted }
          patch("/api/v0/jobs/#{@jobs[0].id}/applications/#{@valid_user_has_applications.id}/accept", headers:)
          expect(response).to have_http_status(403)
        end
        it 'returns [404 Not Found] if job does not exist' do
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_access_token }
          patch("/api/v0/jobs/123123123/applications/#{@valid_user_has_applications.id}/accept", headers:)
          expect(response).to have_http_status(404)
        end
        it 'returns [404 Not Found] if application does not exist' do
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_at_has_own_jobs }
          patch("/api/v0/jobs/#{@jobs[0].id}/applications/123123123123123123132/accept", headers:)
          expect(response).to have_http_status(404)
        end
      end
    end

    describe '(PATCH: /api/v0/jobs/{id}/applications/{id}/reject)' do
      context 'valid normal inputs' do
        it 'returns [200 Ok] and rejects application' do
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_at_has_own_jobs }
          5.times do |i|
            patch("/api/v0/jobs/#{@jobs[i].id}/applications/#{@valid_user_has_applications.id}/reject", headers:)
            expect(response).to have_http_status(200)
          end
        end
        it 'returns [200 Ok] and rejects application with response' do
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_at_has_own_jobs }
          message = 'Not good enough!'
          patch("/api/v0/jobs/#{@jobs[5].id}/applications/#{@valid_user_has_applications.id}/reject?response=#{message}", headers:)
          expect(response).to have_http_status(200)
        end
        it 'returns [404 Not found] if job does not have any applications' do
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_at_has_own_jobs }
          patch("/api/v0/jobs/#{@jobs[6].id}/applications/#{@valid_user_has_applications.id}/reject", headers:)
          expect(response).to have_http_status(404)
        end
      end
      context 'invalid inputs' do
        it 'returns [400 Bad Request] for missing access token in header' do
          patch "/api/v0/jobs/#{@jobs[0].id}/applications/#{@valid_user_has_applications.id}/reject"
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] if application already rejected' do
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_at_has_own_jobs }
          @applications[0].reject('Accepted')
          patch("/api/v0/jobs/#{@jobs[0].id}/applications/#{@valid_user_has_applications.id}/reject", headers:)
          @applications[0].accept('Rejected')
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] and if response message is too long' do
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_at_has_own_jobs }
          message = 'Lorem ipsum venenatis quis sollicitudin elit eros aliquam scelerisque ornare tortor volutpat, quisque ultricies tortor euismod venenatis inceptos quis feugiat condimentum. Bibendum etiam hendrerit pretium odio sit lectus dui congue hendrerit dolor sit, consectetur ante dapibus vitae mi dictumst velit lacus fermentum fames dictum laoreet, nibh tristique quisque aenean mi sociosqu justo rutrum dictum odio. Porttitor turpis hendrerit consequat habitant enim ante urna dictumst convallis ligula massa pharetra'
          patch("/api/v0/jobs/#{@jobs[5].id}/applications/#{@valid_user_has_applications.id}/reject?response=#{message}", headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [401 Unauthorized] for expired/invalid access token' do
          headers = { 'HTTP_ACCESS_TOKEN' => @invalid_access_token }
          patch("/api/v0/jobs/#{@jobs[0].id}/applications/#{@valid_user_has_applications.id}/reject", headers:)
          expect(response).to have_http_status(401)
        end
        it 'returns [403 Forbidden] if user is not owner' do
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_access_token }
          patch("/api/v0/jobs/#{@jobs[0].id}/applications/#{@valid_user_has_applications.id}/reject", headers:)
          expect(response).to have_http_status(403)
        end
        it 'returns [403 Forbidden] for blacklisted user' do
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_at_blacklisted }
          patch("/api/v0/jobs/#{@jobs[0].id}/applications/#{@valid_user_has_applications.id}/reject", headers:)
          expect(response).to have_http_status(403)
        end
        it 'returns [404 Not Found] if job does not exist' do
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_access_token }
          patch("/api/v0/jobs/123123123/applications/#{@valid_user_has_applications.id}/reject", headers:)
          expect(response).to have_http_status(404)
        end
        it 'returns [404 Not Found] if application does not exist' do
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_at_has_own_jobs }
          patch("/api/v0/jobs/#{@jobs[0].id}/applications/123123123123123123132/reject", headers:)
          expect(response).to have_http_status(404)
        end
      end
    end

    describe '(POST: /api/v0/jobs/{id}/applications)' do
      let(:valid_attributes_basic) do
        {
          application_text: 'Hello World'
        }
      end
      let(:invalid_attributes_basic) do
        {
          application_text: 'Lorem ipsum venenatis quis sollicitudin elit eros aliquam scelerisque ornare tortor volutpat, quisque ultricies tortor euismod venenatis inceptos quis feugiat condimentum. Bibendum etiam hendrerit pretium odio sit lectus dui congue hendrerit dolor sit, consectetur ante dapibus vitae mi dictumst velit lacus fermentum fames dictum laoreet, nibh tristique quisque aenean mi sociosqu justo rutrum dictum odio. Porttitor turpis hendrerit consequat habitant enim ante urna dictumst convallis ligula massa pharetra Lorem ipsum venenatis quis sollicitudin elit eros aliquam scelerisque ornare tortor volutpat, quisque ultricies tortor euismod venenatis inceptos quis feugiat condimentum. Bibendum etiam hendrerit pretium odio sit lectus dui congue hendrerit dolor sit, consectetur ante dapibus vitae mi dictumst velit lacus fermentum fames dictum laoreet, nibh tristique quisque aenean mi sociosqu justo rutrum dictum odio. Porttitor turpis hendrerit consequat habitant enim ante urna dictumst convallis ligula massa pharetra'
        }
      end
      let(:blank_attributes_basic) do
        {
          application_text: ''
        }
      end
      let(:valid_attributes_pdf) do
        {
          application_text: 'Hello World',
          application_attachment: Rack::Test::UploadedFile.new(Rails.root.join('spec/assets', 'test_file.pdf'), 'application/pdf')
        }
      end
      let(:valid_attributes_xml) do
        {
          application_text: 'Hello World',
          application_attachment: Rack::Test::UploadedFile.new(Rails.root.join('spec/assets', 'test_file.xml'), 'text/xml')
        }
      end
      let(:valid_attributes_docx) do
        {
          application_text: 'Hello World',
          application_attachment: Rack::Test::UploadedFile.new(Rails.root.join('spec/assets', 'test_file.docx'), 'application/vnd.openxmlformats-officedocument.wordprocessingml.document')
        }
      end
      let(:valid_attributes_txt) do
        {
          application_text: 'Hello World',
          application_attachment: Rack::Test::UploadedFile.new(Rails.root.join('spec/assets', 'test_file.txt'), 'text/plain')
        }
      end
      let(:headers) { { 'HTTP_ACCESS_TOKEN' => @valid_at_applicant } }

      context 'invalid inputs' do
        it 'returns [201 Created] for successfull application not requiring cv' do
          post("/api/v0/jobs/#{@jobs[0].id}/applications", params: valid_attributes_basic, headers:)
          expect(response).to have_http_status(201)
        end
        it 'returns [201 Created] for successfull application requiring cv with \'.pdf\' format' do
          post("/api/v0/jobs/#{@jobs[1].id}/applications", params: valid_attributes_pdf, headers:)
          expect(response).to have_http_status(201)
        end
        it 'returns [201 Created] for successfull application requiring cv with \'.docx\' format' do
          post("/api/v0/jobs/#{@jobs[2].id}/applications", params: valid_attributes_docx, headers:)
          expect(response).to have_http_status(201)
        end
        it 'returns [201 Created] for successfull application requiring cv with \'.txt\' format' do
          post("/api/v0/jobs/#{@jobs[3].id}/applications", params: valid_attributes_txt, headers:)
          expect(response).to have_http_status(201)
        end
        it 'returns [201 Created] for successfull application requiring cv with \'.xml\' format' do
          post("/api/v0/jobs/#{@jobs[4].id}/applications", params: valid_attributes_xml, headers:)
          expect(response).to have_http_status(201)
        end
      end

      context 'invalid inputs' do
        it 'returns [400 Bad Request] for missing access token in header' do
          post "/api/v0/jobs/#{@jobs[0].id}/applications"
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for missing application text' do
          post("/api/v0/jobs/#{@jobs[0].id}/applications", headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for too long application text' do
          post("/api/v0/jobs/#{@jobs[0].id}/applications", params: invalid_attributes_basic, headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for blank application text' do
          post("/api/v0/jobs/#{@jobs[0].id}/applications", params: blank_attributes_basic, headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [401 Unauthorized] for expired/invalid access token' do
          headers = { 'HTTP_ACCESS_TOKEN' => @invalid_access_token }
          post("/api/v0/jobs/#{@jobs[0].id}/applications", params: valid_attributes_docx, headers:)
          expect(response).to have_http_status(401)
        end
        it 'returns [403 Forbidden] for blacklisted user' do
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_at_blacklisted }
          post("/api/v0/jobs/#{@jobs[0].id}/applications", params: valid_attributes_docx, headers:)
          expect(response).to have_http_status(403)
        end
        it 'returns [404 Not Found] if job does not exist' do
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_access_token }
          post('/api/v0/jobs/123123123/applications', params: valid_attributes_docx, headers:)
          expect(response).to have_http_status(404)
        end
        it 'returns [422 Unprocessable Content] for applying with wrong cv format (\'.pdf\' required)' do
          post("/api/v0/jobs/#{@jobs[5].id}/applications", params: valid_attributes_xml, headers:)
          expect(response).to have_http_status(422)
          post("/api/v0/jobs/#{@jobs[5].id}/applications", params: valid_attributes_docx, headers:)
          expect(response).to have_http_status(422)
          post("/api/v0/jobs/#{@jobs[5].id}/applications", params: valid_attributes_txt, headers:)
          expect(response).to have_http_status(422)
        end
        it 'returns [422 Unprocessable Content] for applying with wrong cv format (\'.docx\' required)' do
          post("/api/v0/jobs/#{@jobs[6].id}/applications", params: valid_attributes_xml, headers:)
          expect(response).to have_http_status(422)
          post("/api/v0/jobs/#{@jobs[6].id}/applications", params: valid_attributes_pdf, headers:)
          expect(response).to have_http_status(422)
          post("/api/v0/jobs/#{@jobs[6].id}/applications", params: valid_attributes_txt, headers:)
          expect(response).to have_http_status(422)
        end
        it 'returns [422 Unprocessable Content] for applying with wrong cv format (\'.txt\' required)' do
          post("/api/v0/jobs/#{@jobs[7].id}/applications", params: valid_attributes_xml, headers:)
          expect(response).to have_http_status(422)
          post("/api/v0/jobs/#{@jobs[7].id}/applications", params: valid_attributes_docx, headers:)
          expect(response).to have_http_status(422)
          post("/api/v0/jobs/#{@jobs[7].id}/applications", params: valid_attributes_pdf, headers:)
          expect(response).to have_http_status(422)
        end
        it 'returns [422 Unprocessable Content] for applying with wrong cv format (\'.xml\' required)' do
          post("/api/v0/jobs/#{@jobs[8].id}/applications", params: valid_attributes_pdf, headers:)
          expect(response).to have_http_status(422)
          post("/api/v0/jobs/#{@jobs[8].id}/applications", params: valid_attributes_docx, headers:)
          expect(response).to have_http_status(422)
          post("/api/v0/jobs/#{@jobs[8].id}/applications", params: valid_attributes_txt, headers:)
          expect(response).to have_http_status(422)
        end
        it 'returns [422 Unprocessable Content] if application already submitted' do
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_at_has_applications }
          post("/api/v0/jobs/#{@jobs[0].id}/applications", params: valid_attributes_docx, headers:)
          expect(response).to have_http_status(422)
        end
      end
    end
  end
end
