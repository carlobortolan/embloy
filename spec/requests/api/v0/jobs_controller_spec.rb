# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'JobsController' do
  before(:all) do
    charset = ('a'..'z').to_a + ('A'..'Z').to_a

    ### USER CREATION ###
    # Create basic user
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

    # Create jobs
    5.times do
      @job = Job.create!(
        user_id: @valid_user.id,
        title: 'TestJob',
        description: 'TestDescription',
        longitude: '0.0',
        latitude: '0.0',
        position: 'Intern',
        salary: '123',
        start_slot: Time.now,
        
        key_skills: 'Entrepreneurship',
        duration: '14',
        currency: 'CHF',
        job_type: 'Retail',
        job_type_value: '1'
      )
      puts "Created new job for: #{@valid_user.id}"
    end

    # Create jobs
    @not_owned_job = Job.create!(
      user_id: @blacklisted_user.id,
      title: 'TestJob',
      description: 'TestDescription',
      longitude: '0.0',
      latitude: '0.0',
      position: 'Intern',
      
      salary: '123',
      start_slot: Time.now,
      key_skills: 'Entrepreneurship',
      duration: '14',
      currency: 'CHF',
      job_type: 'Retail',
      job_type_value: '1'
    )
    puts "Created new job for: #{@blacklisted_user.id}"

    # Create jobs
    @private_job = Job.create!(
      user_id: @blacklisted_user.id,
      title: 'TestJob',
      description: 'TestDescription',
      longitude: '0.0',
      latitude: '0.0',
      position: 'Intern',
      salary: '123',
      start_slot: Time.now,
      
      key_skills: 'Entrepreneurship',
      duration: '14',
      currency: 'CHF',
      job_type: 'Retail',
      job_type_value: '1',
      status: 'private'
    )
    puts "Created new job for: #{@blacklisted_user.id}"

    # Verified user refresh/access tokens
    credentials = Base64.strict_encode64("#{@valid_user.email}:password")
    headers = { 'Authorization' => "Basic #{credentials}" }
    post('/api/v0/user/auth/token/refresh', headers:)
    @valid_rt = JSON.parse(response.body)['refresh_token']
    puts "Valid user with upcoming jobs refresh token: #{@valid_rt}"

    headers = { 'HTTP_REFRESH_TOKEN' => @valid_rt }
    post('/api/v0/user/auth/token/access', headers:)
    @valid_at = JSON.parse(response.body)['access_token']
    puts "Valid user with own jobs access token: #{@valid_at}"

    # Blacklisted user refresh/access tokens
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

    @invalid_access_token = 'eyJhbGciOiJIUzI1NiJ9.eyJzdWILOjQ5LCJleHAiOjE2OTgxNzk0MjgsImp0aSI6IjQ1NDMyZWUyNWE4YWUyMjc1ZGY0YTE2ZTNlNmQ0YTY4IiwiaWF0IjoxNjk4MTY1MDI4LCJpc3MiOiJDQl9TdXJmYWNlUHJvOCJ9.nqGgQ6Z52CbaHZzPGcwQG6U-nMDxb1yIe7HQMxjoDTs'
  end

  describe 'Job', type: :request do
    describe '(GET: /api/v0/jobs/{id})' do
      context 'valid normal inputs' do
        it 'returns [200 Ok] and job JSONs if job exists' do
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_at }
          get("/api/v0/jobs/#{@job.id}", headers:)
          expect(response).to have_http_status(200)
        end
        it 'returns [204 No Content] if job does not exist' do
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_at }
          get('/api/v0/jobs/123123123123123123123123', headers:)
          expect(response).to have_http_status(404)
        end
      end
      context 'invalid inputs' do
        it 'returns [400 Bad Request] for missing access token in header' do
          get "/api/v0/jobs/#{@job.id}"
          expect(response).to have_http_status(400)
        end
        it 'returns [401 Unauthorized] for expired/invalid access token' do
          headers = { 'HTTP_ACCESS_TOKEN' => @invalid_access_token }
          get("/api/v0/jobs/#{@job.id}", headers:)
          expect(response).to have_http_status(401)
        end
        it 'returns [403 Forbidden] for blacklisted user' do
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_at_blacklisted }
          get("/api/v0/jobs/#{@job.id}", headers:)
          expect(response).to have_http_status(403)
        end
        it 'returns [403 Forbidden] for private job' do
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_at }
          get("/api/v0/jobs/#{@private_job.id}", headers:)
          expect(response).to have_http_status(403)
        end
        it 'returns [404 Not Found] if job does not exist' do
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_at }
          get('/api/v0/jobs/12312312312312312', headers:)
          expect(response).to have_http_status(404)
          get('/api/v0/jobs/-1', headers:)
          expect(response).to have_http_status(404)
          get('/api/v0/jobs/abc', headers:)
          expect(response).to have_http_status(404)
        end
      end
    end

    describe '(GET: /api/v0/find)' do
      context 'valid normal inputs' do
        it 'returns [200 Ok] and job JSONs if job exists' do
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_at }
          get('/api/v0/find?query=TestJob&job_type=Retail&sort_by=date_desc', headers:)
          expect(response).to have_http_status(200)
        end
        it 'returns [200 Ok] and job JSONs if query blank' do
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_at }
          get('/api/v0/find?job_type=Retail&sort_by=date_desc', headers:)
          expect(response).to have_http_status(200)
        end
        it 'returns [200 Ok] and job JSONs if job_type blank' do
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_at }
          get('/api/v0/find?query=TestJob&sort_by=date_desc', headers:)
          expect(response).to have_http_status(200)
        end
        it 'returns [200 Ok] and job JSONs if sort_by blank' do
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_at }
          get('/api/v0/find?query=TestJob&job_type=Retail', headers:)
          expect(response).to have_http_status(200)
        end
        it 'returns [200 Ok] and job JSONs if params blank' do
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_at }
          get('/api/v0/find', headers:)
          expect(response).to have_http_status(200)
        end
        it 'returns [204 No Content] if no matching jobs exist' do
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_at }
          get('/api/v0/find?query=123&job_type=Food&sort_by=date_desc', headers:)
          expect(response).to have_http_status(204)
        end
        it 'returns [204 No Content] for wrong job_type in params' do
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_at }
          get('/api/v0/find?job_type=test', headers:)
          expect(response).to have_http_status(204)
        end
        it 'returns [204 No Content] for wrong sort_by in params' do
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_at }
          get('/api/v0/find?sort_by=test', headers:)
          expect(response).to have_http_status(204)
        end
      end
      context 'invalid inputs' do
        it 'returns [400 Bad Request] for missing access token in header' do
          { 'HTTP_ACCESS_TOKEN' => @valid_at }
          get '/api/v0/find?query=123&job_type=Food&sort_by=date_desc'
          expect(response).to have_http_status(400)
        end
        it 'returns [401 Unauthorized] for expired/invalid access token' do
          headers = { 'HTTP_ACCESS_TOKEN' => @invalid_access_token }
          get('/api/v0/find?query=123&job_type=Food&sort_by=date_desc', headers:)
          expect(response).to have_http_status(401)
        end
        it 'returns [403 Forbidden] for blacklisted user' do
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_at_blacklisted }
          get('/api/v0/find?query=123&job_type=Food&sort_by=date_desc', headers:)
          expect(response).to have_http_status(403)
        end
      end
    end

    describe '(POST: /api/v0/maps)' do
      context 'valid normal inputs' do
        it 'returns [200 Ok] and job JSONs if job exists' do
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_at }
          get('/api/v0/maps?longitude=0&latitude=0', headers:)
          expect(response).to have_http_status(200)
        end
        it 'returns [204 No Content] if job does not exist' do
          Job.delete_all
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_at }
          get('/api/v0/maps?longitude=0&latitude=0', headers:)
          expect(response).to have_http_status(204)
        end
      end
      context 'invalid inputs' do
        it 'returns [400 Bad Request] for missing access token in header' do
          get('/api/v0/maps?longitude=0&latitude=0', headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for malformed query params' do
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_at }
          get('/api/v0/maps?longitude=180.1&latitude=0', headers:)
          expect(response).to have_http_status(400)
          get('/api/v0/maps?longitude=0&latitude=90.1', headers:)
          expect(response).to have_http_status(400)
          get('/api/v0/maps?longitude=-180.1&latitude=0', headers:)
          expect(response).to have_http_status(400)
          get('/api/v0/maps?longitude=0&latitude=-90.1', headers:)
          expect(response).to have_http_status(400)
          get('/api/v0/maps?longitude=0', headers:)
          expect(response).to have_http_status(400)
          get('/api/v0/maps?latitude=-1', headers:)
          expect(response).to have_http_status(400)
          get('/api/v0/maps', headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [401 Unauthorized] for expired/invalid access token' do
          headers = { 'HTTP_ACCESS_TOKEN' => @invalid_access_token }
          get('/api/v0/maps?longitude=0&latitude=0', headers:)
          expect(response).to have_http_status(401)
        end
        it 'returns [403 Forbidden] for blacklisted user' do
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_at_blacklisted }
          get('/api/v0/maps?longitude=0&latitude=0', headers:)
          expect(response).to have_http_status(403)
        end
      end
    end

    describe '(GET: /api/v0/jobs)' do
      context 'valid normal inputs' do
        it 'returns [500 Internal Server Error] and job JSONs if feed is created' do
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_at }
          get('/api/v0/jobs?longitude=0.0&latitude=0.0', headers:)
          expect(response).to have_http_status(500)
        end
        it 'returns [204 No Content] if no jobs exist' do
          Job.delete_all
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_at }
          get('/api/v0/jobs?longitude=0.0&latitude=0.0', headers:)
          expect(response).to have_http_status(204)
        end
      end
      context 'invalid inputs' do
        it 'returns [400 Bad Request] for missing access token in header' do
          get('/api/v0/jobs?longitude=0&latitude=0.0', headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for malformed query params' do
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_at }
          get('/api/v0/jobs?longitude=180.1&latitude=0', headers:)
          expect(response).to have_http_status(400)
          get('/api/v0/jobs?longitude=0.0&latitude=90.1', headers:)
          expect(response).to have_http_status(400)
          get('/api/v0/jobs?longitude=-180.1&latitude=0', headers:)
          expect(response).to have_http_status(400)
          get('/api/v0/jobs?longitude=0.0&latitude=-90.1', headers:)
          expect(response).to have_http_status(400)
          get('/api/v0/jobs?longitude=0.0', headers:)
          expect(response).to have_http_status(400)
          get('/api/v0/jobs?latitude=-1.0', headers:)
          expect(response).to have_http_status(400)
          get('/api/v0/jobs', headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [401 Unauthorized] for expired/invalid access token' do
          headers = { 'HTTP_ACCESS_TOKEN' => @invalid_access_token }
          get('/api/v0/jobs?longitude=0.0&latitude=0.0', headers:)
          expect(response).to have_http_status(401)
        end
        it 'returns [403 Forbidden] for blacklisted user' do
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_at_blacklisted }
          get('/api/v0/jobs?longitude=0.0&latitude=0.0', headers:)
          expect(response).to have_http_status(403)
        end
      end
    end

    describe '(POST: /api/v0/jobs)' do
      let(:form_data) do
        {
          title: 'TestTitle',
          job_type: 'Retail',
          start_slot: '2024-01-14T03:32:40.555Z',
          position: 'CEO',
          key_skills: 'Entrepreneurship',
          duration: '9',
          salary: '9',
          description: '<div>This is the description</div>',
          status: 'public',
          longitude: '11.613942994844358',
          latitude: '48.1951076',
          job_notifications: '1',
          currency: 'EUR',
          cv_required: false,
          allowed_cv_formats: [".pdf", ".docx", ".txt", ".xml"],
          image_url: Rack::Test::UploadedFile.new(Rails.root.join('spec/assets', 'test_image.png'), 'image/png')
        }
      end
      let(:headers) { { 'HTTP_ACCESS_TOKEN' => @valid_at } }
      context 'valid normal inputs' do
        it 'returns [201 Created] and job JSONs if job exists' do
          post '/api/v0/jobs', params: form_data, headers: headers
          expect(response).to have_http_status(201)
        end
        it 'returns [201 Created] even if missing status' do
          post '/api/v0/jobs', params: form_data.except(:status), headers: headers
          expect(response).to have_http_status(201)
        end
        it 'returns [201 Created] even if missing job_notifications' do
          post '/api/v0/jobs', params: form_data.except(:job_notifications), headers: headers
          expect(response).to have_http_status(201)
        end
        it 'returns [201 Created] even if missing image_url' do
          post '/api/v0/jobs', params: form_data.except(:image_url), headers: headers
          expect(response).to have_http_status(201)
        end
        it 'returns [201 Created] even if missing allowed_cv_format and cv_required false' do
          post '/api/v0/jobs', params: form_data.except(:allowed_cv_format).merge(cv_required: false), headers: headers
          expect(response).to have_http_status(201)
        end
        it 'returns [201 Created] even if missing allowed_cv_format and cv_required true' do
          post '/api/v0/jobs', params: form_data.except(:allowed_cv_format), headers: headers
          expect(response).to have_http_status(201)
        end
        it 'returns [201 Created] even if missing cv_required' do
          post '/api/v0/jobs', params: form_data.except(:cv_required), headers: headers
          expect(response).to have_http_status(201)
        end
      end
      context 'missing fields' do
        it 'returns [400 Bad Request] for missing access token in header' do
          post '/api/v0/jobs'
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for missing title' do
          post '/api/v0/jobs', params: form_data.except(:title), headers: headers
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for missing job_type' do
          post '/api/v0/jobs', params: form_data.except(:job_type), headers: headers
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for missing start_slot' do
          post '/api/v0/jobs', params: form_data.except(:start_slot), headers: headers
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for missing position' do
          post '/api/v0/jobs', params: form_data.except(:position), headers: headers
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for missing key_skills' do
          post '/api/v0/jobs', params: form_data.except(:key_skills), headers: headers
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for missing duration' do
          post '/api/v0/jobs', params: form_data.except(:duration), headers: headers
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for missing salary' do
          post '/api/v0/jobs', params: form_data.except(:salary), headers: headers
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for missing description' do
          post '/api/v0/jobs', params: form_data.except(:description), headers: headers
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for missing longitude' do
          post '/api/v0/jobs', params: form_data.except(:longitude), headers: headers
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for missing latitude' do
          post '/api/v0/jobs', params: form_data.except(:latitude), headers: headers
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for missing currency' do
          post '/api/v0/jobs', params: form_data.except(:currency), headers: headers
          expect(response).to have_http_status(400)
        end
      end
      context 'invalid inputs' do
        it 'returns [400 Bad Request] for invalid start_slot' do
          post '/api/v0/jobs', params: form_data.merge(start_slot: 'invalid'), headers: headers
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for invalid position' do
          post '/api/v0/jobs', params: form_data.merge(position: ''), headers: headers
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for invalid key_skills' do
          post '/api/v0/jobs', params: form_data.merge(key_skills: ''), headers: headers
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for invalid duration' do
          post '/api/v0/jobs', params: form_data.merge(duration: 'invalid'), headers: headers
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for invalid salary' do
          post '/api/v0/jobs', params: form_data.merge(salary: 'invalid'), headers: headers
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for invalid description' do
          post '/api/v0/jobs', params: form_data.merge(description: ''), headers: headers
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for invalid status' do
          post '/api/v0/jobs', params: form_data.merge(status: 'invalid'), headers: headers
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for invalid longitude' do
          post '/api/v0/jobs', params: form_data.merge(longitude: 'invalid'), headers: headers
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for invalid latitude' do
          post '/api/v0/jobs', params: form_data.merge(latitude: 'invalid'), headers: headers
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for invalid job_notifications' do
          post '/api/v0/jobs', params: form_data.merge(job_notifications: 'invalid'), headers: headers
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for invalid currency' do
          post '/api/v0/jobs', params: form_data.merge(currency: 'invalid'), headers: headers
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for invalid allowed_cv_formats' do
          post '/api/v0/jobs', params: form_data.merge(allowed_cv_formats: ['invalid']), headers: headers
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for invalid allowed_cv_formats' do
          post '/api/v0/jobs', params: form_data.merge(allowed_cv_formats: [".pdf", ".invalid"]), headers: headers
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for invalid image_url' do
          post '/api/v0/jobs', params: form_data.merge(image_url: 'invalid'), headers: headers
          expect(response).to have_http_status(400)
        end
      end
      context 'invalid user' do
        it 'returns [401 Unauthorized] for expired/invalid access token' do
          headers = { 'HTTP_ACCESS_TOKEN' => @invalid_access_token }
          post('/api/v0/jobs', headers:)
          expect(response).to have_http_status(401)
        end
        it 'returns [403 Forbidden] for blacklisted user' do
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_at_blacklisted }
          post('/api/v0/jobs', headers:)
          expect(response).to have_http_status(403)
        end
      end
    end

    describe '(PATCH: /api/v0/jobs/#{@job.id})' do
      let(:form_data) do
        {
          title: 'TestTitle',
          job_type: 'Retail',
          start_slot: '2024-01-14T03:32:40.555Z',
          position: 'CEO',
          key_skills: 'Entrepreneurship',
          duration: '9',
          salary: '9',
          description: '<div>This is the description</div>',
          status: 'public',
          longitude: '11.613942994844358',
          latitude: '48.1951076',
          job_notifications: '1',
          currency: 'EUR',
          cv_required: true,
          allowed_cv_formats: [".pdf", ".docx", ".txt", ".xml"],
          image_url: Rack::Test::UploadedFile.new(Rails.root.join('spec/assets', 'test_image.png'), 'image/png')
        }
      end
      let(:headers) { { 'HTTP_ACCESS_TOKEN' => @valid_at } }
      context 'valid normal inputs' do
        it 'returns [200 OK] and job JSONs if job exists' do
          patch "/api/v0/jobs?id=#{@job.id.to_i}", params: form_data, headers: headers
          expect(response).to have_http_status(200)
        end
        it 'returns [200 OK] even if missing status' do
          patch "/api/v0/jobs?id=#{@job.id.to_i}", params: form_data.except(:status), headers: headers
          expect(response).to have_http_status(200)
        end
        it 'returns [200 OK] even if missing job_notifications' do
          patch "/api/v0/jobs?id=#{@job.id.to_i}", params: form_data.except(:job_notifications), headers: headers
          expect(response).to have_http_status(200)
        end
        it 'returns [200 OK] even if missing image_url' do
          patch "/api/v0/jobs?id=#{@job.id.to_i}", params: form_data.except(:image_url), headers: headers
          expect(response).to have_http_status(200)
        end
        it 'returns [200 OK] even if missing allowed_cv_format and cv_required false' do
          patch "/api/v0/jobs?id=#{@job.id.to_i}", params: form_data.except(:allowed_cv_format).merge(cv_required: false), headers: headers
          expect(response).to have_http_status(200)
        end
        it 'returns [200 OK] even if missing allowed_cv_format and cv_required true' do
          patch "/api/v0/jobs?id=#{@job.id.to_i}", params: form_data.except(:allowed_cv_format), headers: headers
          expect(response).to have_http_status(200)
        end
        it 'returns [200 OK] even if missing cv_required' do
          patch "/api/v0/jobs?id=#{@job.id.to_i}", params: form_data.except(:cv_required), headers: headers
          expect(response).to have_http_status(200)
        end
      end
      context 'invalid inputs' do
        it 'returns [400 Bad Request] for invalid start_slot' do
          patch "/api/v0/jobs?id=#{@job.id.to_i}", params: form_data.merge(start_slot: 'invalid'), headers: headers
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for invalid position' do
          patch "/api/v0/jobs?id=#{@job.id.to_i}", params: form_data.merge(position: ''), headers: headers
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for invalid key_skills' do
          patch "/api/v0/jobs?id=#{@job.id.to_i}", params: form_data.merge(key_skills: ''), headers: headers
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for invalid duration' do
          patch "/api/v0/jobs?id=#{@job.id.to_i}", params: form_data.merge(duration: 'invalid'), headers: headers
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for invalid salary' do
          patch "/api/v0/jobs?id=#{@job.id.to_i}", params: form_data.merge(salary: 'invalid'), headers: headers
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for invalid description' do
          patch "/api/v0/jobs?id=#{@job.id.to_i}", params: form_data.merge(description: ''), headers: headers
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for invalid status' do
          patch "/api/v0/jobs?id=#{@job.id.to_i}", params: form_data.merge(status: 'invalid'), headers: headers
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for invalid longitude' do
          patch "/api/v0/jobs?id=#{@job.id.to_i}", params: form_data.merge(longitude: 'invalid'), headers: headers
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for invalid latitude' do
          patch "/api/v0/jobs?id=#{@job.id.to_i}", params: form_data.merge(latitude: 'invalid'), headers: headers
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for invalid job_notifications' do
          patch "/api/v0/jobs?id=#{@job.id.to_i}", params: form_data.merge(job_notifications: 'invalid'), headers: headers
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for invalid currency' do
          patch "/api/v0/jobs?id=#{@job.id.to_i}", params: form_data.merge(currency: 'invalid'), headers: headers
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for invalid allowed_cv_formats' do
          patch "/api/v0/jobs?id=#{@job.id.to_i}", params: form_data.merge(allowed_cv_formats: ['invalid']), headers: headers
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for invalid allowed_cv_formats' do
          patch "/api/v0/jobs?id=#{@job.id.to_i}", params: form_data.merge(allowed_cv_formats: ['.pdf', 'invalid']), headers: headers
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for invalid image_url' do
          patch "/api/v0/jobs?id=#{@job.id.to_i}", params: form_data.merge(image_url: 'invalid'), headers: headers
          expect(response).to have_http_status(400)
        end
      end
      context 'invalid access' do
        it 'returns [401 Unauthorized] for expired/invalid access token' do
          headers = { 'HTTP_ACCESS_TOKEN' => @invalid_access_token }
          patch("/api/v0/jobs?id=#{@job.id.to_i}", headers:)
          expect(response).to have_http_status(401)
        end
        it 'returns [403 Forbidden] for blacklisted user' do
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_at_blacklisted }
          patch("/api/v0/jobs?id=#{@job.id.to_i}", headers:)
          expect(response).to have_http_status(403)
        end
        it 'returns [403 Forbidden] for blacklisted user' do
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_at_blacklisted }
          patch("/api/v0/jobs?id=#{@job.id.to_i}", headers:)
          expect(response).to have_http_status(403)
        end
        it 'returns [403 Forbidden] for user who does not own job' do
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_at }
          patch("/api/v0/jobs?id=#{@not_owned_job.id.to_i}", headers:)
          expect(response).to have_http_status(403)
        end
        it 'returns [403 Forbidden] for private not own job' do
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_at }
          patch("/api/v0/jobs?id=#{@private_job.id.to_i}", headers:)
          expect(response).to have_http_status(403)
        end
        it 'returns [404 Not Found] if job does not exist' do
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_at }
          get('/api/v0/jobs/12312312312312312', headers:)
          expect(response).to have_http_status(404)
          get('/api/v0/jobs/-1', headers:)
          expect(response).to have_http_status(404)
          get('/api/v0/jobs/abc', headers:)
          expect(response).to have_http_status(404)
        end
      end
    end
  end
end
