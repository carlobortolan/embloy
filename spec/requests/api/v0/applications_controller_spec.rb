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
      activity_status: 1
    )

    # Create valid verified user with own jobs
    @valid_user_has_own_jobs = User.create!(
      first_name: 'Max',
      last_name: 'Mustermann',
      email: "#{(0...16).map { charset.sample }.join}@embloy.com",
      password: 'password',
      password_confirmation: 'password',
      user_role: 'verified',
      activity_status: 1
    )
    @valid_user_has_own_jobs.set_payment_processor :fake_processor, allow_fake: true
    @valid_user_has_own_jobs.pay_customers
    @valid_user_has_own_jobs.payment_processor.customer
    @valid_user_has_own_jobs.payment_processor.charge(19_00)
    @valid_user_has_own_jobs.payment_processor.subscribe(plan: 'price_1OUuWFKMiBrigNb6lfAf7ptj')

    # Create valid verified user with own jobs
    @valid_user_has_no_jobs = User.create!(
      first_name: 'Max',
      last_name: 'Mustermann',
      email: "#{(0...16).map { charset.sample }.join}@embloy.com",
      password: 'password',
      password_confirmation: 'password',
      user_role: 'verified',
      activity_status: 1
    )
    @valid_user_has_no_jobs.set_payment_processor :fake_processor, allow_fake: true
    @valid_user_has_no_jobs.pay_customers
    @valid_user_has_no_jobs.payment_processor.customer
    @valid_user_has_no_jobs.payment_processor.charge(19_00)
    @valid_user_has_no_jobs.payment_processor.subscribe(plan: 'price_1OUuWFKMiBrigNb6lfAf7ptj')

    # Create valid verified user with own jobs
    @unsubscribed_user_has_own_jobs = User.create!(
      first_name: 'Max',
      last_name: 'Mustermann',
      email: "#{(0...16).map { charset.sample }.join}@embloy.com",
      password: 'password',
      password_confirmation: 'password',
      user_role: 'verified',
      activity_status: 1
    )
    @unsubscribed_user_has_own_jobs.set_payment_processor :fake_processor, allow_fake: true
    @unsubscribed_user_has_own_jobs.pay_customers
    @unsubscribed_user_has_own_jobs.payment_processor.customer
    @unsubscribed_user_has_own_jobs.payment_processor.charge(19_00)
    @unsubscribed_user_has_own_jobs.payment_processor.subscribe(plan: 'price_1OUuWFKMiBrigNb6lfAf7ptj')

    # Create valid verified user with applications
    @valid_user_has_applications = User.create!(
      first_name: 'Max',
      last_name: 'Mustermann',
      email: "#{(0...16).map { charset.sample }.join}@embloy.com",
      password: 'password',
      password_confirmation: 'password',
      user_role: 'verified',
      activity_status: 1
    )

    # Create valid verified user who will apply for jobs
    @valid_applicant = User.create!(
      first_name: 'Max',
      last_name: 'Mustermann',
      email: "#{(0...16).map { charset.sample }.join}@embloy.com",
      password: 'password',
      password_confirmation: 'password',
      user_role: 'verified',
      activity_status: 1
    )

    # Blacklisted verified user
    @blacklisted_user = User.create!(
      first_name: 'Max',
      last_name: 'Mustermann',
      email: "#{(0...16).map { charset.sample }.join}@embloy.com",
      password: 'password',
      password_confirmation: 'password',
      user_role: 'verified',
      activity_status: 1
    )

    ### ACCESS / REFRESH TOKENS ###

    # Verified user refresh/access tokens
    credentials = Base64.strict_encode64("#{@valid_user.email}:password")
    headers = { 'Authorization' => "Basic #{credentials}" }
    post('/api/v0/auth/token/refresh', headers:)
    @valid_refresh_token = JSON.parse(response.body)['refresh_token']

    headers = { 'HTTP_REFRESH_TOKEN' => @valid_refresh_token }
    post('/api/v0/auth/token/access', headers:)
    @valid_access_token = JSON.parse(response.body)['access_token']

    # Valid user with own jobs refresh/access tokens
    credentials = Base64.strict_encode64("#{@valid_user_has_own_jobs.email}:password")
    headers = { 'Authorization' => "Basic #{credentials}" }
    post('/api/v0/auth/token/refresh', headers:)
    @valid_rt_has_own_jobs = JSON.parse(response.body)['refresh_token']

    headers = { 'HTTP_REFRESH_TOKEN' => @valid_rt_has_own_jobs }
    post('/api/v0/auth/token/access', headers:)
    @valid_at_has_own_jobs = JSON.parse(response.body)['access_token']

    # Valid user with no jobs refresh/access tokens
    credentials = Base64.strict_encode64("#{@valid_user_has_no_jobs.email}:password")
    headers = { 'Authorization' => "Basic #{credentials}" }
    post('/api/v0/auth/token/refresh', headers:)
    @valid_rt_has_no_jobs = JSON.parse(response.body)['refresh_token']

    headers = { 'HTTP_REFRESH_TOKEN' => @valid_rt_has_no_jobs }
    post('/api/v0/auth/token/access', headers:)
    @valid_at_has_no_jobs = JSON.parse(response.body)['access_token']

    # Not subscribed user with own jobs refresh/access tokens
    credentials = Base64.strict_encode64("#{@unsubscribed_user_has_own_jobs.email}:password")
    headers = { 'Authorization' => "Basic #{credentials}" }
    post('/api/v0/auth/token/refresh', headers:)
    @unsubscribed_rt_has_own_jobs = JSON.parse(response.body)['refresh_token']

    headers = { 'HTTP_REFRESH_TOKEN' => @unsubscribed_rt_has_own_jobs }
    post('/api/v0/auth/token/access', headers:)
    @unsubscribed_at_has_own_jobs = JSON.parse(response.body)['access_token']

    # Valid user with upcoming jobs refresh/access tokens
    credentials = Base64.strict_encode64("#{@valid_user_has_applications.email}:password")
    headers = { 'Authorization' => "Basic #{credentials}" }
    post('/api/v0/auth/token/refresh', headers:)
    @valid_rt_has_applications = JSON.parse(response.body)['refresh_token']

    headers = { 'HTTP_REFRESH_TOKEN' => @valid_rt_has_applications }
    post('/api/v0/auth/token/access', headers:)
    @valid_at_has_applications = JSON.parse(response.body)['access_token']

    # Valid user who will apply for jobs refresh/access tokens
    credentials = Base64.strict_encode64("#{@valid_applicant.email}:password")
    headers = { 'Authorization' => "Basic #{credentials}" }
    post('/api/v0/auth/token/refresh', headers:)
    @valid_rt_applicant = JSON.parse(response.body)['refresh_token']

    headers = { 'HTTP_REFRESH_TOKEN' => @valid_rt_applicant }
    post('/api/v0/auth/token/access', headers:)
    @valid_at_applicant = JSON.parse(response.body)['access_token']

    # Blacklisted user refresh/access tokens
    credentials = Base64.strict_encode64("#{@blacklisted_user.email}:password")
    headers = { 'Authorization' => "Basic #{credentials}" }
    post('/api/v0/auth/token/refresh', headers:)
    @valid_rt_blacklisted = JSON.parse(response.body)['refresh_token']

    headers = { 'HTTP_REFRESH_TOKEN' => @valid_rt_blacklisted }
    post('/api/v0/auth/token/access', headers:)
    @valid_at_blacklisted = JSON.parse(response.body)['access_token']

    UserBlacklist.create!(
      user_id: @blacklisted_user.id,
      reason: 'Test blacklist'
    )

    # Invalid/expired access tokens
    @invalid_access_token = 'eyJhbGciOiJIUzI1NiJ9.eyJzdWILOjQ6LCJleHAiOjE2OTgxNzk0MjgsImp0aSI6IjQ1NDMyZWUyNWE4YWUyMjc1ZGY0YTE2ZTNlNmQ0YTY4IiwiaWF0IjoxNjk4MTY1MDI4LCJpc3MiOiJDQl9TdXJmYWNlUHJvOCJ9.nqGgQ6Z52CbaHZzPGcwQG6U-nMDxb1yIe7HQMxjoDTs'

    # OWN JOBS & UPCOMING JOBS
    # Create own jobs for valid verified user (valid_user_has_own_jobs) and upcoming jobs for valid verified user (valid_user_has_upcoming_jobs)
    cv_required = [false, true, true, true, true, true, true, true, true, false, false, false]
    allowed_cv_formats = [['.pdf', '.docx', '.txt', '.xml'], ['.pdf'], ['.docx'], ['.txt'], ['.xml'], ['.pdf'], ['.docx'], ['.txt'], ['.xml']]
    activity_status = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0]
    status = %w[listed listed listed listed listed listed listed listed listed unlisted archived listed]
    @jobs = []
    @applications = []
    12.times do |i|
      @jobs << Job.create!(
        user_id: @valid_user_has_own_jobs.id,
        job_status: status[i],
        activity_status: activity_status[i],
        cv_required: cv_required[i],
        allowed_cv_formats: allowed_cv_formats[i]
      )
    end
    6.times do |i|
      @applications << Application.create!(
        user_id: @valid_user_has_applications.id,
        job_id: @jobs[i].id,
        application_text: 'TestUpcomingApplicationText',
        response: 'No response yet ...',
        status: '0'
      )
    end

    @applications << Application.create!(
      user_id: @valid_user_has_applications.id,
      job_id: @jobs[9].id,
      application_text: 'TestUpcomingApplicationText',
      response: 'No response yet ...',
      status: '0'
    )

    activity_status = [1, 1, 1, 1, 1, 0]
    status = %w[listed listed listed unlisted archived listed]
    required = [true, true, false, false, false, false]
    6.times do |i|
      job = Job.create!(
        user_id: @valid_user_has_own_jobs.id,
        job_status: status[i],
        activity_status: activity_status[i]
      )
      job.application_options.create!(
        question: 'TEST Text',
        question_type: 'short_text',
        required: required[i]
      )
      job.application_options.create!(
        question: 'TEST SC',
        question_type: 'single_choice',
        required: required[i],
        options: %w[TestOption1 TestOption2 TestOption3]
      )
      job.application_options.create!(
        question: 'TEST MC',
        question_type: 'multiple_choice',
        required: required[i],
        options: %w[TestOption1 TestOption2 TestOption3]
      )
      job.application_options.create!(
        question: 'TEST LINK',
        question_type: 'link',
        required: required[i]
      )
      job.application_options.create!(
        question: 'TEST Yes/No',
        question_type: 'yes_no',
        required: required[i]
      )
      job.application_options.create!(
        question: 'TEST Text',
        question_type: 'long_text',
        required: required[i]
      )
      job.application_options.create!(
        question: 'TEST Text',
        question_type: 'number',
        required: required[i]
      )
      job.application_options.create!(
        question: 'TEST Text',
        question_type: 'date',
        required: required[i]
      )
      job.application_options.create!(
        question: 'TEST Text',
        question_type: 'location',
        required: required[i]
      )
      job.application_options.create!(
        question: 'TEST Text',
        question_type: 'file',
        required: required[i],
        options: %w[pdf docx txt]
      )
      job.application_options.create!(
        question: 'TEST Text',
        question_type: 'file',
        required: required[i],
        options: []
      )
      job.application_options.create!(
        question: 'TEST Text',
        question_type: 'file',
        required: required[i]
      )
      @jobs << job
    end

    @jobs << Job.create!(
      user_id: @unsubscribed_user_has_own_jobs.id,
      job_status: 'listed',
      activity_status: 1
    )
    @unsubscribed_user_has_own_jobs.payment_processor.subscription.cancel_now!
  end

  describe 'User', type: :request do
    describe '(GET: /api/v0/user/applications)' do
      context 'valid normal inputs' do
        it 'returns [200 Ok] and JSON application JSONs if user has applications' do
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_at_has_applications }
          5.times do |_i|
            get('/api/v0/user/applications', headers:)
            expect(response).to have_http_status(200)
          end
        end
        it 'returns [204 No Content] if user does not have any applications' do
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_at_has_own_jobs }
          get('/api/v0/user/applications', headers:)
          expect(response).to have_http_status(204)
        end
      end
      context 'invalid inputs' do
        it 'returns [400 Bad Request] for missing access token in header' do
          get('/api/v0/user/applications')
          expect(response).to have_http_status(400)
        end
        it 'returns [401 Unauthorized] for expired/invalid access token' do
          headers = { 'HTTP_ACCESS_TOKEN' => @invalid_access_token }
          get('/api/v0/user/applications', headers:)
          expect(response).to have_http_status(401)
        end
        it 'returns [403 Forbidden] for blacklisted user' do
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_at_blacklisted }
          get('/api/v0/user/applications', headers:)
          expect(response).to have_http_status(403)
        end
      end
    end
    describe '(GET: /api/v0/jobs/upcoming)' do
      context 'valid normal inputs' do
        it 'returns [200 Ok] and JSON application JSONs if user has upcoming jobs' do
          @applications.each do |application|
            application.accept('Accepted')
          end
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_at_has_applications }
          5.times do |_i|
            get('/api/v0/user/upcoming', headers:)
            expect(response).to have_http_status(200)
          end
        end
        it 'returns [204 No Content] if user does not have any upcoming jobs' do
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_at_has_applications }
          get('/api/v0/user/upcoming', headers:)
          expect(response).to have_http_status(204)
        end
      end
      context 'invalid inputs' do
        it 'returns [400 Bad Request] for missing access token in header' do
          get('/api/v0/user/upcoming')
          expect(response).to have_http_status(400)
        end
        it 'returns [401 Unauthorized] for expired/invalid access token' do
          headers = { 'HTTP_ACCESS_TOKEN' => @invalid_access_token }
          get('/api/v0/user/upcoming', headers:)
          expect(response).to have_http_status(401)
        end
        it 'returns [403 Forbidden] for blacklisted user' do
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_at_blacklisted }
          get('/api/v0/user/upcoming', headers:)
          expect(response).to have_http_status(403)
        end
      end
    end
  end

  describe 'Applications', type: :request do
    describe '(GET: /api/v0/applications)' do
      context 'valid normal inputs' do
        it 'returns [200 Ok] and JSON application JSONs employer has applications' do
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_at_has_own_jobs }
          get('/api/v0/applications', headers:)
          expect(response).to have_http_status(200)
        end
        it 'returns [204 No Content] if employer does not have any applications' do
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_at_applicant }
          get('/api/v0/applications', headers:)
          expect(response).to have_http_status(204)
        end
      end
      context 'invalid inputs' do
        it 'returns [400 Bad Request] for missing access token in header' do
          get('/api/v0/jobs/applications')
          expect(response).to have_http_status(400)
        end
        it 'returns [401 Unauthorized] for expired/invalid access token' do
          headers = { 'HTTP_ACCESS_TOKEN' => @invalid_access_token }
          get('/api/v0/jobs/applications', headers:)
          expect(response).to have_http_status(401)
        end
        it 'returns [403 Forbidden] for blacklisted user' do
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_at_blacklisted }
          get('/api/v0/jobs/applications', headers:)
          expect(response).to have_http_status(403)
        end
      end
    end

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
        it 'returns [403 Forbidden] if user is not owner' do
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_at_has_no_jobs }
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

    describe '(GET: /api/v0/jobs/{id}/applications/{application_id})' do
      context 'valid normal inputs' do
        it 'returns [200 Ok] and JSON application JSONs if job has application for specific user' do
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_at_has_own_jobs }
          5.times do |i|
            get("/api/v0/jobs/#{@jobs[i].id}/applications/#{@valid_user_has_applications.id}", headers:)
            expect(response).to have_http_status(200)
          end
        end
        it 'returns [404 Not Found] if job does not have any applications' do
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_at_has_own_jobs }
          get("/api/v0/jobs/#{@jobs[6].id}/applications/#{@valid_user_has_applications.id}", headers:)
          expect(response).to have_http_status(204)
        end
      end
      context 'invalid inputs' do
        it 'returns [400 Bad Request] for missing access token in header' do
          get("/api/v0/jobs/#{@jobs[1].id}/applications/#{@valid_user_has_applications.id}")
          expect(response).to have_http_status(400)
        end
        it 'returns [401 Unauthorized] for expired/invalid access token' do
          headers = { 'HTTP_ACCESS_TOKEN' => @invalid_access_token }
          get("/api/v0/jobs/#{@jobs[1].id}/applications/#{@valid_user_has_applications.id}", headers:)
          expect(response).to have_http_status(401)
        end
        it 'returns [403 Forbidden] if user is not owner' do
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_access_token }
          get("/api/v0/jobs/#{@jobs[1].id}/applications/#{@valid_user_has_applications.id}", headers:)
          expect(response).to have_http_status(403)
        end
        it 'returns [403 Forbidden] if user is not owner' do
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_at_has_no_jobs }
          get("/api/v0/jobs/#{@jobs[1].id}/applications/#{@valid_user_has_applications.id}", headers:)
          expect(response).to have_http_status(403)
        end
        it 'returns [403 Forbidden] for blacklisted user' do
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_at_blacklisted }
          get("/api/v0/jobs/#{@jobs[1].id}/applications/#{@valid_user_has_applications.id}", headers:)
          expect(response).to have_http_status(403)
        end
        it 'returns [404 Not Found] if job does not exist' do
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_access_token }
          get('/api/v0/jobs/131231231231231312312/applications/12320831', headers:)
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
        it 'returns [200 OK] for unlisted job and accepts application' do
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_at_has_own_jobs }
          patch("/api/v0/jobs/#{@jobs[9].id}/applications/#{@valid_user_has_applications.id}/accept", headers:)
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
        it 'returns [403 Forbidden] for unsubscribed user' do
          headers = { 'HTTP_ACCESS_TOKEN' => @unsubscribed_at_has_own_jobs }
          patch("/api/v0/jobs/#{@jobs[18].id}/applications/#{@valid_user_has_applications.id}/accept", headers:)
          expect(response).to have_http_status(403)
        end
        it 'returns [403 Forbidden] if user is not owner' do
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_at_has_no_jobs }
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
        it 'returns [409 Conflict] for archived job' do
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_at_has_own_jobs }
          patch("/api/v0/jobs/#{@jobs[10].id}/applications/#{@valid_user_has_applications.id}/accept", headers:)
          expect(response).to have_http_status(409)
        end
        it 'returns [409 Conflict] for deactivated job' do
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_at_has_own_jobs }
          patch("/api/v0/jobs/#{@jobs[11].id}/applications/#{@valid_user_has_applications.id}/accept", headers:)
          expect(response).to have_http_status(409)
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
        it 'returns [200 OK] for unlisted job and rejects application' do
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_at_has_own_jobs }
          patch("/api/v0/jobs/#{@jobs[9].id}/applications/#{@valid_user_has_applications.id}/reject", headers:)
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
        it 'returns [403 Forbidden] for unsubscribed user' do
          headers = { 'HTTP_ACCESS_TOKEN' => @unsubscribed_at_has_own_jobs }
          patch("/api/v0/jobs/#{@jobs[18].id}/applications/#{@valid_user_has_applications.id}/reject", headers:)
          expect(response).to have_http_status(403)
        end
        it 'returns [403 Forbidden] if user is not owner' do
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_at_has_no_jobs }
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
        it 'returns [409 Conflict] for archived job' do
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_at_has_own_jobs }
          patch("/api/v0/jobs/#{@jobs[10].id}/applications/#{@valid_user_has_applications.id}/reject", headers:)
          expect(response).to have_http_status(409)
        end
        it 'returns [409 Conflict] for deactivated job' do
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_at_has_own_jobs }
          patch("/api/v0/jobs/#{@jobs[11].id}/applications/#{@valid_user_has_applications.id}/reject", headers:)
          expect(response).to have_http_status(409)
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

      context 'valid inputs' do
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
        it 'returns [409 Conflict] for unlisted job' do
          post("/api/v0/jobs/#{@jobs[9].id}/applications", params: valid_attributes_basic, headers:)
          expect(response).to have_http_status(409)
        end
        it 'returns [409 Conflict] for archived job' do
          post("/api/v0/jobs/#{@jobs[10].id}/applications", params: valid_attributes_basic, headers:)
          expect(response).to have_http_status(409)
        end
        it 'returns [409 Conflict] for inactive job' do
          post("/api/v0/jobs/#{@jobs[11].id}/applications", params: valid_attributes_basic, headers:)
          expect(response).to have_http_status(409)
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

      context 'application options' do
        let(:valid_attributes_with_required_answer) do
          {
            application_text: 'Hello World',
            application_answers: {
              '0' => {
                application_option_id: @jobs[12].application_options[0].id,
                answer: 'a' * 200
              },
              '1' => {
                application_option_id: @jobs[12].application_options[1].id,
                answer: 'TestOption1'
              },
              '2' => {
                application_option_id: @jobs[12].application_options[2].id,
                answer: 'TestOption1||| TestOption2'
              },
              '3' => {
                application_option_id: @jobs[12].application_options[3].id,
                answer: 'https://embloy.com'
              },
              '4' => {
                application_option_id: @jobs[12].application_options[4].id,
                answer: 'Yes'
              },
              '5' => {
                application_option_id: @jobs[12].application_options[5].id,
                answer: 'a' * 1000
              },
              '6' => {
                application_option_id: @jobs[12].application_options[6].id,
                answer: '1'
              },
              '7' => {
                application_option_id: @jobs[12].application_options[7].id,
                answer: Time.now
              },
              '8' => {
                application_option_id: @jobs[12].application_options[8].id,
                answer: 'This is an address'
              },
              '9' => {
                application_option_id: @jobs[12].application_options[9].id,
                file: Rack::Test::UploadedFile.new(Rails.root.join('spec/assets', 'test_file.pdf'), 'application/pdf')
              },
              '10' => {
                application_option_id: @jobs[12].application_options[10].id,
                file: Rack::Test::UploadedFile.new(Rails.root.join('spec/assets', 'test_file.pdf'), 'application/pdf')
              },
              '11' => {
                application_option_id: @jobs[12].application_options[11].id,
                file: Rack::Test::UploadedFile.new(Rails.root.join('spec/assets', 'test_file.pdf'), 'application/pdf')
              }
            }
          }
        end
        let(:valid_attributes_with_optional_answer) do
          {
            application_text: 'Hello World',
            application_answers: {
              '0' => {
                application_option_id: @jobs[13].application_options[0].id,
                answer: 'a' * 200
              },
              '1' => {
                application_option_id: @jobs[13].application_options[1].id,
                answer: 'TestOption1'
              },
              '2' => {
                application_option_id: @jobs[13].application_options[2].id,
                answer: 'TestOption1||| TestOption2'
              },
              '3' => {
                application_option_id: @jobs[13].application_options[3].id,
                answer: 'https://embloy.com'
              },
              '4' => {
                application_option_id: @jobs[13].application_options[4].id,
                answer: 'Yes'
              },
              '5' => {
                application_option_id: @jobs[13].application_options[5].id,
                answer: 'a' * 1000
              },
              '6' => {
                application_option_id: @jobs[13].application_options[6].id,
                answer: '1'
              },
              '7' => {
                application_option_id: @jobs[13].application_options[7].id,
                answer: Time.now
              },
              '8' => {
                application_option_id: @jobs[13].application_options[8].id,
                answer: 'a' * 1000
              },
              '9' => {
                application_option_id: @jobs[13].application_options[9].id,
                file: Rack::Test::UploadedFile.new(Rails.root.join('spec/assets', 'test_file.pdf'), 'application/pdf')
              },
              '10' => {
                application_option_id: @jobs[13].application_options[10].id,
                file: Rack::Test::UploadedFile.new(Rails.root.join('spec/assets', 'test_file.pdf'), 'application/pdf')
              },
              '11' => {
                application_option_id: @jobs[13].application_options[11].id,
                file: Rack::Test::UploadedFile.new(Rails.root.join('spec/assets', 'test_file.pdf'), 'application/pdf')
              }
            }
          }
        end
        let(:invalid_attributes_with_answer) do
          {
            application_text: 'Test Text',
            application_answers: {
              '0' => {
                application_option_id: @jobs[14].application_options[0].id,
                answer: 'a' * 201
              },
              '1' => {
                application_option_id: @jobs[14].application_options[1].id,
                answer: 'TestOption1||| TestOption2||| TestOption3'
              },
              '2' => {
                application_option_id: @jobs[14].application_options[2].id,
                answer: 'TestOption1||| TestOption2||| TestOption3||| TestOption4'
              },
              '3' => {
                application_option_id: @jobs[14].application_options[3].id,
                answer: 'not-a-link'
              },
              '4' => {
                application_option_id: @jobs[14].application_options[4].id,
                answer: 'Hello World'
              },
              '5' => {
                application_option_id: @jobs[14].application_options[5].id,
                answer: 'a' * 1001
              },
              '6' => {
                application_option_id: @jobs[14].application_options[6].id,
                answer: '1a'
              },
              '7' => {
                application_option_id: @jobs[14].application_options[7].id,
                answer: 'not-a-date'
              },
              '8' => {
                application_option_id: @jobs[14].application_options[8].id,
                answer: 'a' * 1001
              },
              '9' => {
                application_option_id: @jobs[14].application_options[9].id,
                file: Rack::Test::UploadedFile.new(Rails.root.join('spec/assets', 'test_image.png'), 'image/png')
              },
              '10' => {
                application_option_id: @jobs[14].application_options[10].id
              }
            }
          }
        end

        it 'returns [201 Created] for successful application with required application answer' do
          post("/api/v0/jobs/#{@jobs[12].id}/applications", params: valid_attributes_with_required_answer, headers:)
          expect(response).to have_http_status(201)
        end

        it 'returns [201 Created] for successful application with optional application answer' do
          post("/api/v0/jobs/#{@jobs[13].id}/applications", params: valid_attributes_with_optional_answer, headers:)
          puts "Response code: #{response.status}"
          puts "Response body: #{response.body}"
          expect(response).to have_http_status(201)
        end

        it 'returns [400 Bad Request] for missing required application answer (short_text)' do
          valid_attributes = valid_attributes_with_required_answer.dup
          valid_attributes[:application_answers].delete('0')
          post("/api/v0/jobs/#{@jobs[12].id}/applications", params: valid_attributes, headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for missing required application answer (single_choice)' do
          valid_attributes = valid_attributes_with_required_answer.dup
          valid_attributes[:application_answers].delete('1')
          post("/api/v0/jobs/#{@jobs[12].id}/applications", params: valid_attributes, headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for missing required application answer (multiple_choice)' do
          valid_attributes = valid_attributes_with_required_answer.dup
          valid_attributes[:application_answers].delete('2')
          post("/api/v0/jobs/#{@jobs[12].id}/applications", params: valid_attributes, headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for missing required application answer (link)' do
          valid_attributes = valid_attributes_with_required_answer.dup
          valid_attributes[:application_answers].delete('3')
          post("/api/v0/jobs/#{@jobs[12].id}/applications", params: valid_attributes, headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for missing required application answer (yes_no)' do
          valid_attributes = valid_attributes_with_required_answer.dup
          valid_attributes[:application_answers].delete('4')
          post("/api/v0/jobs/#{@jobs[12].id}/applications", params: valid_attributes, headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for missing required application answer (long_text)' do
          valid_attributes = valid_attributes_with_required_answer.dup
          valid_attributes[:application_answers].delete('5')
          post("/api/v0/jobs/#{@jobs[12].id}/applications", params: valid_attributes, headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for missing required application answer (number)' do
          valid_attributes = valid_attributes_with_required_answer.dup
          valid_attributes[:application_answers].delete('6')
          post("/api/v0/jobs/#{@jobs[12].id}/applications", params: valid_attributes, headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for missing required application answer (date)' do
          valid_attributes = valid_attributes_with_required_answer.dup
          valid_attributes[:application_answers].delete('7')
          post("/api/v0/jobs/#{@jobs[12].id}/applications", params: valid_attributes, headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for missing required application answer (location)' do
          valid_attributes = valid_attributes_with_required_answer.dup
          valid_attributes[:application_answers].delete('8')
          post("/api/v0/jobs/#{@jobs[12].id}/applications", params: valid_attributes, headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for missing required application answer (file 1)' do
          valid_attributes = valid_attributes_with_required_answer.dup
          valid_attributes[:application_answers].delete('9')
          post("/api/v0/jobs/#{@jobs[12].id}/applications", params: valid_attributes, headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for missing required application answer (file 2)' do
          valid_attributes = valid_attributes_with_required_answer.dup
          valid_attributes[:application_answers].delete('10')
          post("/api/v0/jobs/#{@jobs[12].id}/applications", params: valid_attributes, headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for missing required application answer (file 3)' do
          valid_attributes = valid_attributes_with_required_answer.dup
          valid_attributes[:application_answers].delete('11')
          post("/api/v0/jobs/#{@jobs[12].id}/applications", params: valid_attributes, headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for too long short-text answer' do
          invalid_attributes = invalid_attributes_with_answer.dup
          invalid_attributes[:application_answers] = { '0' => invalid_attributes[:application_answers]['0'] }
          post("/api/v0/jobs/#{@jobs[13].id}/applications", params: invalid_attributes, headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for invalid single choice answer' do
          invalid_attributes = invalid_attributes_with_answer.dup
          invalid_attributes[:application_answers] = { '1' => invalid_attributes[:application_answers]['1'] }
          post("/api/v0/jobs/#{@jobs[13].id}/applications", params: invalid_attributes, headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for invalid multiple choice answer' do
          invalid_attributes = invalid_attributes_with_answer.dup
          invalid_attributes[:application_answers] = { '2' => invalid_attributes[:application_answers]['2'] }
          post("/api/v0/jobs/#{@jobs[13].id}/applications", params: invalid_attributes, headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for invalid link answer' do
          invalid_attributes = invalid_attributes_with_answer.dup
          invalid_attributes[:application_answers] = { '3' => invalid_attributes[:application_answers]['3'] }
          post("/api/v0/jobs/#{@jobs[13].id}/applications", params: invalid_attributes, headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for too long long-text answer' do
          invalid_attributes = invalid_attributes_with_answer.dup
          invalid_attributes[:application_answers] = [invalid_attributes[:application_answers]['5']]
          post("/api/v0/jobs/#{@jobs[13].id}/applications", params: invalid_attributes, headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for invalid number answer' do
          invalid_attributes = invalid_attributes_with_answer.dup
          invalid_attributes[:application_answers] = [invalid_attributes[:application_answers]['6']]
          post("/api/v0/jobs/#{@jobs[13].id}/applications", params: invalid_attributes, headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for invalid date answer' do
          invalid_attributes = invalid_attributes_with_answer.dup
          invalid_attributes[:application_answers] = [invalid_attributes[:application_answers]['7']]
          post("/api/v0/jobs/#{@jobs[13].id}/applications", params: invalid_attributes, headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for invalid location answer' do
          invalid_attributes = invalid_attributes_with_answer.dup
          invalid_attributes[:application_answers] = [invalid_attributes[:application_answers]['8']]
          post("/api/v0/jobs/#{@jobs[13].id}/applications", params: invalid_attributes, headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for invalid filetype' do
          invalid_attributes = invalid_attributes_with_answer.dup
          invalid_attributes[:application_answers] = [invalid_attributes[:application_answers]['9']]
          post("/api/v0/jobs/#{@jobs[13].id}/applications", params: invalid_attributes, headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for missing file' do
          invalid_attributes = invalid_attributes_with_answer.dup
          invalid_attributes[:application_answers] = [invalid_attributes[:application_answers]['10']]
          post("/api/v0/jobs/#{@jobs[13].id}/applications", params: invalid_attributes, headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for invalid application_option_id' do
          invalid_attributes = valid_attributes_with_required_answer.dup
          invalid_attributes[:application_answers]['0'][:application_option_id] = -1
          post("/api/v0/jobs/#{@jobs[12].id}/applications", params: invalid_attributes, headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for missing application_option_id in application_answers' do
          invalid_attributes = valid_attributes_with_required_answer.dup
          invalid_attributes[:application_answers]['0'].delete(:application_option_id)
          post("/api/v0/jobs/#{@jobs[12].id}/applications", params: invalid_attributes, headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for non-integer application_option_id' do
          invalid_attributes = valid_attributes_with_required_answer.dup
          invalid_attributes[:application_answers]['0'][:application_option_id] = 'invalid'
          post("/api/v0/jobs/#{@jobs[12].id}/applications", params: invalid_attributes, headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for invalid single_choice answer' do
          invalid_attributes = invalid_attributes_with_answer.dup
          invalid_attributes[:application_answers]['1'][:answer] = 'InvalidOption'
          post("/api/v0/jobs/#{@jobs[13].id}/applications", params: invalid_attributes, headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for invalid link answer' do
          invalid_attributes = invalid_attributes_with_answer.dup
          invalid_attributes[:application_answers]['3'][:answer] = 'not-a-link'
          post("/api/v0/jobs/#{@jobs[13].id}/applications", params: invalid_attributes, headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for invalid yes_no answer' do
          invalid_attributes = invalid_attributes_with_answer.dup
          invalid_attributes[:application_answers]['4'][:answer] = 'maybe'
          post("/api/v0/jobs/#{@jobs[13].id}/applications", params: invalid_attributes, headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for invalid application_option' do
          invalid_attributes = valid_attributes_with_required_answer.dup
          invalid_attributes[:application_answers]['0'][:application_option_id] = -1
          post("/api/v0/jobs/#{@jobs[12].id}/applications", params: invalid_attributes, headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [409 Conflict] for unlisted job' do
          post("/api/v0/jobs/#{@jobs[15].id}/applications", params: valid_attributes_with_required_answer, headers:)
          expect(response).to have_http_status(409)
        end
        it 'returns [409 Conflict] for archived job' do
          post("/api/v0/jobs/#{@jobs[16].id}/applications", params: valid_attributes_with_required_answer, headers:)
          expect(response).to have_http_status(409)
        end
        it 'returns [409 Conflict] for inactive job' do
          post("/api/v0/jobs/#{@jobs[17].id}/applications", params: valid_attributes_with_required_answer, headers:)
          expect(response).to have_http_status(409)
        end
      end
    end
  end
end
