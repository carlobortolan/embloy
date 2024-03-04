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
      user_role: :verified,
      activity_status: 1
    )
    @valid_user.set_payment_processor :fake_processor, allow_fake: true
    @valid_user.pay_customers
    @valid_user.payment_processor.customer
    @valid_user.payment_processor.charge(19_00)
    @valid_user.payment_processor.subscribe(plan: 'price_1OUuWFKMiBrigNb6lfAf7ptj')

    # Create user with embloy-basic subscription
    @user_basic = User.create!(
      first_name: 'Max',
      last_name: 'Mustermann',
      email: "#{(0...16).map { charset.sample }.join}@embloy.com",
      password: 'password',
      password_confirmation: 'password',
      user_role: 'verified',
      activity_status: 1
    )
    @user_basic.set_payment_processor :fake_processor, allow_fake: true
    @user_basic.pay_customers
    @user_basic.payment_processor.customer
    @user_basic.payment_processor.charge(19_00)
    @user_basic.payment_processor.subscribe(plan: 'price_1On8ItKMiBrigNb6eZ9PKFG0')

    # Create user with embloy-premium subscription
    @user_premium = User.create!(
      first_name: 'Max',
      last_name: 'Mustermann',
      email: "#{(0...16).map { charset.sample }.join}@embloy.com",
      password: 'password',
      password_confirmation: 'password',
      user_role: 'verified',
      activity_status: 1
    )
    @user_premium.set_payment_processor :fake_processor, allow_fake: true
    @user_premium.pay_customers
    @user_premium.payment_processor.customer
    @user_premium.payment_processor.charge(19_00)
    @user_premium.payment_processor.subscribe(plan: 'price_1On8KvKMiBrigNb6bZG4nWQh')

    # Create valid unverified user
    @unverified_user = User.create!(
      first_name: 'Max',
      last_name: 'Mustermann',
      email: "#{(0...16).map { charset.sample }.join}@embloy.com",
      password: 'password',
      password_confirmation: 'password',
      user_role: 'spectator',
      activity_status: 0
    )
    @unverified_user.set_payment_processor :fake_processor, allow_fake: true
    @unverified_user.pay_customers
    @unverified_user.payment_processor.customer
    @unverified_user.payment_processor.charge(19_00)
    @unverified_user.payment_processor.subscribe(plan: 'price_1OUuWFKMiBrigNb6lfAf7ptj')

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
    @blacklisted_user.set_payment_processor :fake_processor, allow_fake: true
    @blacklisted_user.pay_customers
    @blacklisted_user.payment_processor.customer
    @blacklisted_user.payment_processor.charge(19_00)
    @blacklisted_user.payment_processor.subscribe(plan: 'price_1OUuWFKMiBrigNb6lfAf7ptj')

    # Blacklisted verified user
    @unsubscribed_user = User.create!(
      first_name: 'Max',
      last_name: 'Mustermann',
      email: "#{(0...16).map { charset.sample }.join}@embloy.com",
      password: 'password',
      password_confirmation: 'password',
      user_role: 'verified',
      activity_status: 1
    )

    # Create jobs
    5.times do
      @job = Job.create!(
        user_id: @valid_user.id,
        title: "TestJob",
        job_type: "Retail",
        job_status: 'listed',
        activity_status: 1
      )
    end

    # Create jobs
    3.times do
      @user_basic_job = Job.create!(
        user_id: @user_basic.id
      )
    end

    # Create jobs
    50.times do
      @user_premium_job = Job.create!(
        user_id: @user_premium.id,
        job_status: 'listed',
        activity_status: 1
      )
    end

    # Create jobs
    @not_owned_job = Job.create!(
      user_id: @blacklisted_user.id,
      activity_status: 1
    )

    # Create jobs
    @unlisted_job = Job.create!(
      user_id: @valid_user.id,
      activity_status: 1,
      job_status: 'unlisted'
    )

    # Create jobs
    @not_owned_unlisted_job = Job.create!(
      user_id: @blacklisted_user.id,
      activity_status: 1,
      job_status: 'unlisted'
    )

    # Create jobs
    @not_owned_archived_job = Job.create!(
      user_id: @blacklisted_user.id,
      activity_status: 1,
      job_status: 'archived'
    )

    # Create jobs
    @archived_job = Job.create!(
      user_id: @valid_user.id,
      activity_status: 1,
      job_status: 'archived'
    )

    # Create jobs
    @inactive_job = Job.create!(
      user_id: @valid_user.id,
      activity_status: 0,
      job_status: 'listed'
    )

    # Verified user refresh/access tokens
    credentials = Base64.strict_encode64("#{@valid_user.email}:password")
    headers = { 'Authorization' => "Basic #{credentials}" }
    post('/api/v0/auth/token/refresh', headers:)
    @valid_rt = JSON.parse(response.body)['refresh_token']

    headers = { 'HTTP_REFRESH_TOKEN' => @valid_rt }
    post('/api/v0/auth/token/access', headers:)
    @valid_at = JSON.parse(response.body)['access_token']

    # User with embloy-basic subscription refresh/access tokens
    credentials = Base64.strict_encode64("#{@user_basic.email}:password")
    headers = { 'Authorization' => "Basic #{credentials}" }
    post('/api/v0/auth/token/refresh', headers:)
    @basic_rt = JSON.parse(response.body)['refresh_token']

    headers = { 'HTTP_REFRESH_TOKEN' => @basic_rt }
    post('/api/v0/auth/token/access', headers:)
    @basic_at = JSON.parse(response.body)['access_token']

    # User with embloy-premium subscription refresh/access tokens
    credentials = Base64.strict_encode64("#{@user_premium.email}:password")
    headers = { 'Authorization' => "Basic #{credentials}" }
    post('/api/v0/auth/token/refresh', headers:)
    @premium_rt = JSON.parse(response.body)['refresh_token']

    headers = { 'HTTP_REFRESH_TOKEN' => @premium_rt }
    post('/api/v0/auth/token/access', headers:)
    @premium_at = JSON.parse(response.body)['access_token']

    # Unsubscribed user refresh/access tokens
    credentials = Base64.strict_encode64("#{@unsubscribed_user.email}:password")
    headers = { 'Authorization' => "Basic #{credentials}" }
    post('/api/v0/auth/token/refresh', headers:)
    @unsubscribed_rt = JSON.parse(response.body)['refresh_token']

    headers = { 'HTTP_REFRESH_TOKEN' => @unsubscribed_rt }
    post('/api/v0/auth/token/access', headers:)
    @unsubscribed_at = JSON.parse(response.body)['access_token']

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

    @invalid_access_token = 'eyJhbGciOiJIUzI1NiJ9.eyJzdWILOjQ5LCJleHAiOjE2OTgxNzk0MjgsImp0aSI6IjQ1NDMyZWUyNWE4YWUyMjc1ZGY0YTE2ZTNlNmQ0YTY4IiwiaWF0IjoxNjk4MTY1MDI4LCJpc3MiOiJDQl9TdXJmYWNlUHJvOCJ9.nqGgQ6Z52CbaHZzPGcwQG6U-nMDxb1yIe7HQMxjoDTs'
  end

  describe 'Job', type: :request do
    describe '(GET: /api/v0/jobs/{id})' do
      context 'valid normal inputs' do
        it 'returns [200 Ok] and job JSONs if job is listed' do
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_at }
          get("/api/v0/jobs/#{@job.id}", headers:)
          expect(response).to have_http_status(200)
        end
        it 'returns [200 Ok] and job JSONs if job is listed' do
          headers = { 'HTTP_ACCESS_TOKEN' => @unsubscribed_at }
          get("/api/v0/jobs/#{@job.id}", headers:)
          expect(response).to have_http_status(200)
        end
        it 'returns [200 Ok] and job JSONs if job is unlisted and user is owner' do
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_at }
          get("/api/v0/jobs/#{@unlisted_job.id}", headers:)
          expect(response).to have_http_status(200)
        end
        it 'returns [200 Ok] and job JSONs if job is archived and user is owner' do
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_at }
          get("/api/v0/jobs/#{@archived_job.id}", headers:)
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
        it 'returns [403 Forbidden] for unlisted job' do
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_at }
          get("/api/v0/jobs/#{@not_owned_unlisted_job.id}", headers:)
          expect(response).to have_http_status(403)
        end
        it 'returns [403 Forbidden] for archived job' do
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_at }
          get("/api/v0/jobs/#{@not_owned_archived_job.id}", headers:)
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
          start_slot: Time.now + 1.year,
          position: 'CEO',
          key_skills: 'Entrepreneurship',
          duration: '9',
          salary: '9',
          description: '<div>This is the description</div>',
          job_status: 'listed',
          longitude: '11.613942994844358',
          latitude: '48.1951076',
          job_notifications: '1',
          currency: 'EUR',
          cv_required: false,
          allowed_cv_formats: ['.pdf', '.docx', '.txt', '.xml'],
          image_url: Rack::Test::UploadedFile.new(Rails.root.join('spec/assets', 'test_image.png'), 'image/png')
        }
      end
      let(:headers) { { 'HTTP_ACCESS_TOKEN' => @valid_at } }

      context 'subscription limits reached' do
        it 'returns [429 Too Many Requests] if user creates more jobs than what his subscription (basic) allows' do
          post('/api/v0/jobs', params: form_data, headers: { 'HTTP_ACCESS_TOKEN' => @basic_at })
          expect(response).to have_http_status(429)
        end
        it 'returns [429 Too Many Requests] if user creates more jobs than what his subscription (premium) allows' do
          post('/api/v0/jobs', params: form_data, headers: { 'HTTP_ACCESS_TOKEN' => @premium_at })
          expect(response).to have_http_status(429)
        end
      end
      context 'valid normal inputs' do
        it 'returns [201 Created] and job JSONs if job exists' do
          post('/api/v0/jobs', params: form_data, headers:)
          expect(response).to have_http_status(201)
        end
        it 'returns [201 Created] even if missing job_status' do
          post('/api/v0/jobs', params: form_data.except(:job_status), headers:)
          expect(response).to have_http_status(201)
        end
        it 'returns [201 Created] even if missing job_notifications' do
          post('/api/v0/jobs', params: form_data.except(:job_notifications), headers:)
          expect(response).to have_http_status(201)
        end
        it 'returns [201 Created] even if missing image_url' do
          post('/api/v0/jobs', params: form_data.except(:image_url), headers:)
          expect(response).to have_http_status(201)
        end
        it 'returns [201 Created] even if missing allowed_cv_format and cv_required false' do
          post('/api/v0/jobs', params: form_data.except(:allowed_cv_format).merge(cv_required: false), headers:)
          expect(response).to have_http_status(201)
        end
        it 'returns [201 Created] even if missing allowed_cv_format and cv_required true' do
          post('/api/v0/jobs', params: form_data.except(:allowed_cv_format), headers:)
          expect(response).to have_http_status(201)
        end
      end
      context 'missing fields' do
        it 'returns [400 Bad Request] for missing access token in header' do
          post '/api/v0/jobs'
          expect(response).to have_http_status(400)
        end
        it 'returns [201 Created] for missing title' do
          post('/api/v0/jobs', params: form_data.except(:title), headers:)
          expect(response).to have_http_status(201)
        end
        it 'returns [201 Created] for missing job_type' do
          post('/api/v0/jobs', params: form_data.except(:job_type), headers:)
          expect(response).to have_http_status(201)
        end
        it 'returns [201 Created] for missing start_slot' do
          post('/api/v0/jobs', params: form_data.except(:start_slot), headers:)
          expect(response).to have_http_status(201)
        end
        it 'returns [201 Created] for missing position' do
          post('/api/v0/jobs', params: form_data.except(:position), headers:)
          expect(response).to have_http_status(201)
        end
        it 'returns [201 Created] for missing key_skills' do
          post('/api/v0/jobs', params: form_data.except(:key_skills), headers:)
          expect(response).to have_http_status(201)
        end
        it 'returns [201 Created] for missing duration' do
          post('/api/v0/jobs', params: form_data.except(:duration), headers:)
          expect(response).to have_http_status(201)
        end
        it 'returns [201 Created] for missing salary' do
          post('/api/v0/jobs', params: form_data.except(:salary), headers:)
          expect(response).to have_http_status(201)
        end
        it 'returns [201 Created] for missing description' do
          post('/api/v0/jobs', params: form_data.except(:description), headers:)
          expect(response).to have_http_status(201)
        end
        it 'returns [201 Created] for missing longitude' do
          post('/api/v0/jobs', params: form_data.except(:longitude), headers:)
          expect(response).to have_http_status(201)
        end
        it 'returns [201 Created] for missing latitude' do
          post('/api/v0/jobs', params: form_data.except(:latitude), headers:)
          expect(response).to have_http_status(201)
        end
        it 'returns [201 Created] for missing currency' do
          post('/api/v0/jobs', params: form_data.except(:currency), headers:)
          expect(response).to have_http_status(201)
        end
        it 'returns [201 Created] if missing cv_required' do
          post('/api/v0/jobs', params: form_data.except(:cv_required), headers:)
          expect(response).to have_http_status(201)
        end
      end
      context 'invalid inputs' do
        it 'returns [400 Bad Request] for invalid start_slot' do
          post('/api/v0/jobs', params: form_data.merge(start_slot: 1.year.ago), headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for invalid position' do
          post('/api/v0/jobs', params: form_data.merge(position: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'), headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for invalid key_skills' do
          post('/api/v0/jobs', params: form_data.merge(key_skills: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'), headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for invalid duration' do
          post('/api/v0/jobs', params: form_data.merge(duration: -99_999_999_999_999), headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for invalid salary' do
          post('/api/v0/jobs', params: form_data.merge(salary: 'invalid'), headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for invalid salary' do
          post('/api/v0/jobs', params: form_data.merge(salary: 0), headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for invalid salary' do
          post('/api/v0/jobs', params: form_data.merge(salary: -123_456_789), headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for invalid description' do
          post('/api/v0/jobs',
               params: form_data.merge(description: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'), headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for invalid job_status' do
          post('/api/v0/jobs', params: form_data.merge(job_status: 'invalid'), headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for invalid job_status' do
          post('/api/v0/jobs', params: form_data.merge(job_status: 123), headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for invalid job_status' do
          post('/api/v0/jobs', params: form_data.merge(job_status: -123), headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for invalid longitude' do
          post('/api/v0/jobs', params: form_data.merge(longitude: 'invalid'), headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for invalid longitude' do
          post('/api/v0/jobs', params: form_data.merge(longitude: 181), headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for invalid longitude' do
          post('/api/v0/jobs', params: form_data.merge(longitude: -181), headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for invalid latitude' do
          post('/api/v0/jobs', params: form_data.merge(latitude: 'invalid'), headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for invalid latitude' do
          post('/api/v0/jobs', params: form_data.merge(latitude: 91), headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for invalid latitude' do
          post('/api/v0/jobs', params: form_data.merge(latitude: -91), headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for invalid job_notifications' do
          post('/api/v0/jobs', params: form_data.merge(job_notifications: 'invalid'), headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for invalid job_notifications' do
          post('/api/v0/jobs', params: form_data.merge(job_notifications: 5), headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for invalid currency' do
          post('/api/v0/jobs', params: form_data.merge(currency: 'invalid'), headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for invalid allowed_cv_formats' do
          post('/api/v0/jobs', params: form_data.merge(allowed_cv_formats: [1, 2, 3, 4]), headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for invalid allowed_cv_formats' do
          post('/api/v0/jobs', params: form_data.merge(allowed_cv_formats: ['invalid']), headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for invalid allowed_cv_formats' do
          post('/api/v0/jobs', params: form_data.merge(allowed_cv_formats: ['.pdf', '.invalid']), headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for invalid image_url' do
          post('/api/v0/jobs', params: form_data.merge(image_url: 'invalid'), headers:)
          expect(response).to have_http_status(400)
        end
      end
      context 'invalid user' do
        it 'returns [403 Forbidden] for expired/invalid access token' do
          headers = { 'HTTP_ACCESS_TOKEN' => @invalid_access_token }
          post('/api/v0/jobs', headers:)
          expect(response).to have_http_status(401)
        end
        it 'returns [403 Forbidden] for expired/missing subscription' do
          headers = { 'HTTP_ACCESS_TOKEN' => @unsubscribed_at }
          post('/api/v0/jobs', headers:)
          expect(response).to have_http_status(403)
        end
        it 'returns [403 Forbidden] for blacklisted user' do
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_at_blacklisted }
          post('/api/v0/jobs', headers:)
          expect(response).to have_http_status(403)
        end
      end
      context 'application options tests' do
        let(:form_data_with_options) do
          form_data.merge(
            application_options_attributes: [
              {
                question: 'Do you have experience with marketing?',
                question_type: 'yes_no',
                required: true,
                options: []
              },
              {
                question: 'What is your highest level of education?',
                question_type: 'single_choice',
                required: true,
                options: ['High School', "Bachelor's Degree", "Master's Degree"]
              },
              {
                question: 'What is your highest level of education?',
                question_type: 'multiple_choice',
                required: true,
                options: ['High School', "Bachelor's Degree", "Master's Degree"]
              },
              {
                question: 'What is your highest level of education?',
                question_type: 'text',
                required: false
              },
              {
                question: 'What is your highest level of education?',
                question_type: 'text',
                required: true
              },
              {
                question: 'What is your highest level of education?',
                question_type: 'link',
                required: true
              }
            ]
          )
        end
        it 'returns [201 Created] and job JSONs if application options are valid' do
          post('/api/v0/jobs', params: form_data_with_options, headers:)
          expect(response).to have_http_status(201)
        end
        it 'returns [400 Bad Request] if application options question is empty' do
          form_data_with_options[:application_options_attributes][0][:question] = ''
          post('/api/v0/jobs', params: form_data_with_options, headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] if application options question_type is invalid' do
          form_data_with_options[:application_options_attributes][0][:question_type] = 'invalid_type'
          post('/api/v0/jobs', params: form_data_with_options, headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] if application options options field is empty' do
          form_data_with_options[:application_options_attributes][1][:options] = []
          post('/api/v0/jobs', params: form_data_with_options, headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] if application options options field has more than 25 options' do
          form_data_with_options[:application_options_attributes][1][:options] = Array.new(26, 'a')
          post('/api/v0/jobs', params: form_data_with_options, headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] if application options options field has more than 25 options' do
          form_data_with_options[:application_options_attributes][2][:options] = Array.new(26, 'a')
          post('/api/v0/jobs', params: form_data_with_options, headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] if application options options is too long' do
          form_data_with_options[:application_options_attributes][1][:options] = ['aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa']
          post('/api/v0/jobs', params: form_data_with_options, headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] if application options options field is empty' do
          form_data_with_options[:application_options_attributes][2][:options] = []
          post('/api/v0/jobs', params: form_data_with_options, headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] if application question it invalid' do
          form_data_with_options[:application_options_attributes][0][:question] = ''
          post('/api/v0/jobs', params: form_data_with_options, headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] if application question is too long' do
          form_data_with_options[:application_options_attributes][0][:question] =
            'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
          post('/api/v0/jobs', params: form_data_with_options, headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] if application options question is null' do
          form_data_with_options[:application_options_attributes][0][:question] = nil
          post('/api/v0/jobs', params: form_data_with_options, headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] if application options options field is missing for single_choice' do
          form_data_with_options[:application_options_attributes][1].delete(:options)
          post('/api/v0/jobs', params: form_data_with_options, headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] if application options options field is missing for multiple_choice' do
          form_data_with_options[:application_options_attributes][2].delete(:options)
          post('/api/v0/jobs', params: form_data_with_options, headers:)
          expect(response).to have_http_status(400)
        end
      end
    end

    describe "(PATCH: /api/v0/jobs/\#{@job.id})" do
      let(:form_data) do
        {
          title: 'TestTitle',
          job_type: 'Retail',
          start_slot: Time.now + 1.year,
          position: 'CEO',
          key_skills: 'Entrepreneurship',
          duration: '9',
          salary: '9',
          description: '<div>This is the description</div>',
          job_status: 'listed',
          longitude: '11.613942994844358',
          latitude: '48.1951076',
          job_notifications: '1',
          currency: 'EUR',
          cv_required: true,
          allowed_cv_formats: ['.pdf', '.docx', '.txt', '.xml'],
          image_url: Rack::Test::UploadedFile.new(Rails.root.join('spec/assets', 'test_image.png'), 'image/png')
        }
      end
      let(:headers) { { 'HTTP_ACCESS_TOKEN' => @valid_at } }
      context 'valid normal inputs' do
        it 'returns [200 OK] and job JSONs if job exists' do
          patch("/api/v0/jobs?id=#{@job.id.to_i}", params: form_data, headers:)
          expect(response).to have_http_status(200)
        end
        it 'returns [200 OK] even if missing job_status' do
          patch("/api/v0/jobs?id=#{@job.id.to_i}", params: form_data.except(:job_status), headers:)
          expect(response).to have_http_status(200)
        end
        it 'returns [200 OK] even if missing job_notifications' do
          patch("/api/v0/jobs?id=#{@job.id.to_i}", params: form_data.except(:job_notifications), headers:)
          expect(response).to have_http_status(200)
        end
        it 'returns [200 OK] even if missing image_url' do
          patch("/api/v0/jobs?id=#{@job.id.to_i}", params: form_data.except(:image_url), headers:)
          expect(response).to have_http_status(200)
        end
        it 'returns [200 OK] even if missing allowed_cv_format and cv_required false' do
          patch("/api/v0/jobs?id=#{@job.id.to_i}", params: form_data.except(:allowed_cv_format).merge(cv_required: false), headers:)
          expect(response).to have_http_status(200)
        end
        it 'returns [200 OK] even if missing allowed_cv_format and cv_required true' do
          patch("/api/v0/jobs?id=#{@job.id.to_i}", params: form_data.except(:allowed_cv_format), headers:)
          expect(response).to have_http_status(200)
        end
        it 'returns [200 OK] even if missing cv_required' do
          patch("/api/v0/jobs?id=#{@job.id.to_i}", params: form_data.except(:cv_required), headers:)
          expect(response).to have_http_status(200)
        end
      end
      context 'invalid inputs' do
        it 'returns [400 Bad Request] for invalid start_slot' do
          patch("/api/v0/jobs?id=#{@job.id.to_i}", params: form_data.merge(start_slot: 1.year.ago), headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for invalid position' do
          patch("/api/v0/jobs?id=#{@job.id.to_i}", params: form_data.merge(position: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'),
                                                   headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for invalid key_skills' do
          patch("/api/v0/jobs?id=#{@job.id.to_i}", params: form_data.merge(key_skills: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'),
                                                   headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for invalid duration' do
          patch("/api/v0/jobs?id=#{@job.id.to_i}", params: form_data.merge(duration: -99_999_999_999_999), headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for invalid salary' do
          patch("/api/v0/jobs?id=#{@job.id.to_i}", params: form_data.merge(salary: 'invalid'), headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for invalid salary' do
          patch("/api/v0/jobs?id=#{@job.id.to_i}", params: form_data.merge(salary: 0), headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for invalid salary' do
          patch("/api/v0/jobs?id=#{@job.id.to_i}", params: form_data.merge(salary: -123_456_789), headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for invalid description' do
          patch("/api/v0/jobs?id=#{@job.id.to_i}",
                params: form_data.merge(description: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'), headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for invalid job_status' do
          patch("/api/v0/jobs?id=#{@job.id.to_i}", params: form_data.merge(job_status: 'invalid'), headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for invalid job_status' do
          patch("/api/v0/jobs?id=#{@job.id.to_i}", params: form_data.merge(job_status: 123), headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for invalid job_status' do
          patch("/api/v0/jobs?id=#{@job.id.to_i}", params: form_data.merge(job_status: -123), headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for invalid longitude' do
          patch("/api/v0/jobs?id=#{@job.id.to_i}", params: form_data.merge(longitude: 'invalid'), headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for invalid longitude' do
          patch("/api/v0/jobs?id=#{@job.id.to_i}", params: form_data.merge(longitude: 181), headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for invalid longitude' do
          patch("/api/v0/jobs?id=#{@job.id.to_i}", params: form_data.merge(longitude: -181), headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for invalid latitude' do
          patch("/api/v0/jobs?id=#{@job.id.to_i}", params: form_data.merge(latitude: 'invalid'), headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for invalid latitude' do
          patch("/api/v0/jobs?id=#{@job.id.to_i}", params: form_data.merge(latitude: 91), headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for invalid latitude' do
          patch("/api/v0/jobs?id=#{@job.id.to_i}", params: form_data.merge(latitude: -91), headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for invalid job_notifications' do
          patch("/api/v0/jobs?id=#{@job.id.to_i}", params: form_data.merge(job_notifications: 'invalid'), headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for invalid job_notifications' do
          patch("/api/v0/jobs?id=#{@job.id.to_i}", params: form_data.merge(job_notifications: 5), headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for invalid currency' do
          patch("/api/v0/jobs?id=#{@job.id.to_i}", params: form_data.merge(currency: 'invalid'), headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for invalid allowed_cv_formats' do
          patch("/api/v0/jobs?id=#{@job.id.to_i}", params: form_data.merge(allowed_cv_formats: [1, 2, 3, 4]), headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for invalid allowed_cv_formats' do
          patch("/api/v0/jobs?id=#{@job.id.to_i}", params: form_data.merge(allowed_cv_formats: ['invalid']), headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for invalid allowed_cv_formats' do
          patch("/api/v0/jobs?id=#{@job.id.to_i}", params: form_data.merge(allowed_cv_formats: ['.pdf', '.invalid']), headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for invalid image_url' do
          patch("/api/v0/jobs?id=#{@job.id.to_i}", params: form_data.merge(image_url: 'invalid'), headers:)
          expect(response).to have_http_status(400)
        end
      end
      context 'application options tests' do
        let(:form_data_with_options) do
          form_data.merge(
            application_options_attributes: [
              {
                question: 'Do you have experience with marketing?',
                question_type: 'yes_no',
                required: true,
                options: []
              },
              {
                question: 'What is your highest level of education?',
                question_type: 'single_choice',
                required: true,
                options: ['High School', "Bachelor's Degree", "Master's Degree"]
              },
              {
                question: 'What is your highest level of education?',
                question_type: 'multiple_choice',
                required: true,
                options: ['High School', "Bachelor's Degree", "Master's Degree"]
              },
              {
                question: 'What is your highest level of education?',
                question_type: 'text',
                required: false
              },
              {
                question: 'What is your highest level of education?',
                question_type: 'text',
                required: true
              },
              {
                question: 'What is your highest level of education?',
                question_type: 'link',
                required: true
              }
            ]
          )
        end
        it 'returns [200 OK] and job JSONs if application options are valid' do
          patch("/api/v0/jobs?id=#{@job.id.to_i}", params: form_data_with_options, headers:)
          expect(response).to have_http_status(200)
        end
        it 'returns [400 Bad Request] if application options question is empty' do
          form_data_with_options[:application_options_attributes][0][:question] = ''
          patch("/api/v0/jobs?id=#{@job.id.to_i}", params: form_data_with_options, headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] if application options question_type is invalid' do
          form_data_with_options[:application_options_attributes][0][:question_type] = 'invalid_type'
          patch("/api/v0/jobs?id=#{@job.id.to_i}", params: form_data_with_options, headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] if application options options field is empty' do
          form_data_with_options[:application_options_attributes][1][:options] = []
          patch("/api/v0/jobs?id=#{@job.id.to_i}", params: form_data_with_options, headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] if application options options field has more than 25 options' do
          form_data_with_options[:application_options_attributes][1][:options] = Array.new(26, 'a')
          patch("/api/v0/jobs?id=#{@job.id.to_i}", params: form_data_with_options, headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] if application options options field has more than 25 options' do
          form_data_with_options[:application_options_attributes][2][:options] = Array.new(26, 'a')
          patch("/api/v0/jobs?id=#{@job.id.to_i}", params: form_data_with_options, headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] if application options options is too long' do
          form_data_with_options[:application_options_attributes][1][:options] = ['aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa']
          patch("/api/v0/jobs?id=#{@job.id.to_i}", params: form_data_with_options, headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] if application options options field is empty' do
          form_data_with_options[:application_options_attributes][2][:options] = []
          patch("/api/v0/jobs?id=#{@job.id.to_i}", params: form_data_with_options, headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] if application question it invalid' do
          form_data_with_options[:application_options_attributes][0][:question] = ''
          patch("/api/v0/jobs?id=#{@job.id.to_i}", params: form_data_with_options, headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] if application question is too long' do
          form_data_with_options[:application_options_attributes][0][:question] =
            'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
          patch("/api/v0/jobs?id=#{@job.id.to_i}", params: form_data_with_options, headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] if application options question is null' do
          form_data_with_options[:application_options_attributes][0][:question] = nil
          patch("/api/v0/jobs?id=#{@job.id.to_i}", params: form_data_with_options, headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] if application options options field is missing for single_choice' do
          form_data_with_options[:application_options_attributes][1].delete(:options)
          patch("/api/v0/jobs?id=#{@job.id.to_i}", params: form_data_with_options, headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] if application options options field is missing for multiple_choice' do
          form_data_with_options[:application_options_attributes][2].delete(:options)
          patch("/api/v0/jobs?id=#{@job.id.to_i}", params: form_data_with_options, headers:)
          expect(response).to have_http_status(400)
        end
      end
      context 'invalid access' do
        it 'returns [401 Unauthorized] for expired/invalid access token' do
          headers = { 'HTTP_ACCESS_TOKEN' => @invalid_access_token }
          patch("/api/v0/jobs?id=#{@job.id.to_i}", headers:)
          expect(response).to have_http_status(401)
        end
        it 'returns [401 Unauthorized] for expired/missing subscription' do
          headers = { 'HTTP_ACCESS_TOKEN' => @unsubscribed_at }
          patch("/api/v0/jobs?id=#{@job.id.to_i}", headers:)
          expect(response).to have_http_status(403)
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
        it 'returns [403 Forbidden] for unlisted not owned job' do
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_at }
          patch("/api/v0/jobs?id=#{@not_owned_unlisted_job.id.to_i}", headers:)
          expect(response).to have_http_status(403)
        end
        it 'returns [403 Forbidden] if user updates jobs with cancelled subscription' do
          @user_basic.payment_processor.subscription.cancel_now!
          patch("/api/v0/jobs?id=#{@user_basic_job.id.to_i}", params: form_data, headers: { 'HTTP_ACCESS_TOKEN' => @basic_at })
          expect(response).to have_http_status(403)
        end
        it 'returns [403 Forbidden] if user updates jobs with cancelled subscription' do
          @user_premium.payment_processor.subscription.cancel_now!
          patch("/api/v0/jobs?id=#{@user_premium_job.id.to_i}", params: form_data, headers: { 'HTTP_ACCESS_TOKEN' => @premium_at })
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
        it 'returns [409 Conflict] for archived job' do
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_at }
          patch("/api/v0/jobs?id=#{@archived_job.id.to_i}", headers:)
          expect(response).to have_http_status(409)
        end
        it 'returns [409 Conflict] for archived not owned job' do
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_at }
          patch("/api/v0/jobs?id=#{@not_owned_archived_job.id.to_i}", headers:)
          expect(response).to have_http_status(409)
        end
        it 'returns [409 Conflict] if job is inactive' do
          patch("/api/v0/jobs?id=#{@inactive_job.id.to_i}", params: form_data, headers:)
          expect(response).to have_http_status(409)
        end
        it 'returns [429 Too Many Requests] if user updates jobs while having more jobs than what his subscription (premium) allows' do
          @user_premium.payment_processor.subscription.cancel_now!
          @user_premium.payment_processor.subscribe(plan: 'price_1On8ItKMiBrigNb6eZ9PKFG0')
          patch("/api/v0/jobs?id=#{@user_premium_job.id.to_i}", params: form_data, headers: { 'HTTP_ACCESS_TOKEN' => @premium_at })
          expect(response).to have_http_status(429)
        end
      end
    end
  end
end
