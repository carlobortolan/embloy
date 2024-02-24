# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'QuicklinkController' do
  before(:all) do
    charset = ('a'..'z').to_a + ('A'..'Z').to_a

    ### USER CREATION ###
    # Create user with valid subscription, own jobs, upcoming jobs, reviews, ...
    @valid_user = User.create!(
      first_name: 'Max',
      last_name: 'Mustermann',
      email: "#{(0...16).map { charset.sample }.join}@embloy.com",
      password: 'password',
      password_confirmation: 'password',
      user_role: 'verified',
      activity_status: 1
    )
    @valid_user.set_payment_processor :fake_processor, allow_fake: true
    @valid_user.pay_customers
    @valid_user.payment_processor.customer
    @valid_user.payment_processor.charge(19_00)
    @valid_user.payment_processor.subscribe(plan: 'price_1OUuWFKMiBrigNb6lfAf7ptj')

    # Create user with soon expiring subscription, own jobs, upcoming jobs, reviews, ...
    @valid_user_exp = User.create!(
      first_name: 'Max',
      last_name: 'Mustermann',
      email: "#{(0...16).map { charset.sample }.join}@embloy.com",
      password: 'password',
      password_confirmation: 'password',
      user_role: 'verified',
      activity_status: 1
    )
    @valid_user_exp.set_payment_processor :fake_processor, allow_fake: true
    @valid_user_exp.pay_customers
    @valid_user_exp.payment_processor.customer
    @valid_user_exp.payment_processor.charge(19_00)
    @valid_user_exp.payment_processor.subscribe(plan: 'price_1OUuWFKMiBrigNb6lfAf7ptj')

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

    # Create valid verified user who already has applied
    @valid_user_has_applied = User.create!(
      first_name: 'Max',
      last_name: 'Mustermann',
      email: "#{(0...16).map { charset.sample }.join}@embloy.com",
      password: 'password',
      password_confirmation: 'password',
      user_role: 'verified',
      activity_status: 1
    )

    # Create user without valid subscription, own jobs, upcoming jobs, reviews, ...
    @unsubscribed_user = User.create!(
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
    @blacklisted_user.set_payment_processor :fake_processor, allow_fake: true
    @blacklisted_user.pay_customers
    @blacklisted_user.payment_processor.customer
    @blacklisted_user.payment_processor.charge(19_00)
    @blacklisted_user.payment_processor.subscribe(plan: 'price_1OUuWFKMiBrigNb6lfAf7ptj')

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

    ### JOB CREATION ###

    # Create jobs
    5.times do
      @job = Job.create!(
        user_id: @valid_user_has_own_jobs.id,
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
      user_id: @valid_user_has_own_jobs.id,
      job_status: 'unlisted',
      activity_status: 1
    )

    # Create jobs
    @not_owned_unlisted_job = Job.create!(
      user_id: @blacklisted_user.id,
      job_status: 'unlisted',
      activity_status: 1
    )

    # Create jobs
    @not_owned_archived_job = Job.create!(
      user_id: @blacklisted_user.id,
      job_status: 'archived',
      activity_status: 1
    )

    # Create jobs
    @archived_job = Job.create!(
      user_id: @valid_user_has_own_jobs.id,
      job_status: 'archived',
      activity_status: 1
    )

    # Create jobs
    @inactive_job = Job.create!(
      user_id: @valid_user_has_own_jobs.id,
      job_status: 'listed',
      activity_status: 0
    )

    ### ACCESS / REFRESH TOKENS ###

    # Verified user refresh/access/client tokens
    credentials = Base64.strict_encode64("#{@valid_user.email}:password")
    headers = { 'Authorization' => "Basic #{credentials}" }
    post('/api/v0/auth/token/refresh', headers:)
    @valid_refresh_token = JSON.parse(response.body)['refresh_token']

    headers = { 'HTTP_REFRESH_TOKEN' => @valid_refresh_token }
    post('/api/v0/auth/token/access', headers:)
    @valid_access_token = JSON.parse(response.body)['access_token']

    headers = { 'HTTP_ACCESS_TOKEN' => @valid_access_token }
    post('/api/v0/auth/token/client', headers:)
    @valid_client_token = JSON.parse(response.body)['client_token']

    # Verified user with soon expiring subscription refresh/access/client tokens
    credentials = Base64.strict_encode64("#{@valid_user_exp.email}:password")
    headers = { 'Authorization' => "Basic #{credentials}" }
    post('/api/v0/auth/token/refresh', headers:)
    @valid_rt_exp = JSON.parse(response.body)['refresh_token']

    headers = { 'HTTP_REFRESH_TOKEN' => @valid_rt_exp }
    post('/api/v0/auth/token/access', headers:)
    @valid_at_exp = JSON.parse(response.body)['access_token']

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

    # Valid user with own jobs refresh/access/client tokens
    credentials = Base64.strict_encode64("#{@valid_user_has_own_jobs.email}:password")
    headers = { 'Authorization' => "Basic #{credentials}" }
    post('/api/v0/auth/token/refresh', headers:)
    @valid_rt_has_own_jobs = JSON.parse(response.body)['refresh_token']

    headers = { 'HTTP_REFRESH_TOKEN' => @valid_rt_has_own_jobs }
    post('/api/v0/auth/token/access', headers:)
    @valid_at_has_own_jobs = JSON.parse(response.body)['access_token']

    @valid_ct_has_own_jobs = QuicklinkService::Client.encode(@valid_user_has_own_jobs.id.to_i, Time.now.to_i + (60 * 60 * 24 * 31 * 3), 'premium', Time.now.to_i)

    # Valid user who has applied refresh/access/client tokens
    credentials = Base64.strict_encode64("#{@valid_user_has_applied.email}:password")
    headers = { 'Authorization' => "Basic #{credentials}" }
    post('/api/v0/auth/token/refresh', headers:)
    @valid_rt_has_applied = JSON.parse(response.body)['refresh_token']

    headers = { 'HTTP_REFRESH_TOKEN' => @valid_rt_has_applied }
    post('/api/v0/auth/token/access', headers:)
    @valid_at_has_applied = JSON.parse(response.body)['access_token']

    headers = { 'HTTP_ACCESS_TOKEN' => @valid_at_has_applied }
    post('/api/v0/auth/token/client', headers:)
    @valid_ct_has_applied = JSON.parse(response.body)['client_token']

    # Unsubscribed refresh/access/client tokens
    credentials = Base64.strict_encode64("#{@unsubscribed_user.email}:password")
    headers = { 'Authorization' => "Basic #{credentials}" }
    post('/api/v0/auth/token/refresh', headers:)
    @valid_rt_unsubscribed = JSON.parse(response.body)['refresh_token']

    headers = { 'HTTP_REFRESH_TOKEN' => @valid_rt_unsubscribed }
    post('/api/v0/auth/token/access', headers:)
    @valid_at_unsubscribed = JSON.parse(response.body)['access_token']

    # Blacklisted user refresh/access/client tokens
    credentials = Base64.strict_encode64("#{@blacklisted_user.email}:password")
    headers = { 'Authorization' => "Basic #{credentials}" }
    post('/api/v0/auth/token/refresh', headers:)
    @valid_rt_blacklisted = JSON.parse(response.body)['refresh_token']

    headers = { 'HTTP_REFRESH_TOKEN' => @valid_rt_blacklisted }
    post('/api/v0/auth/token/access', headers:)
    @valid_at_blacklisted = JSON.parse(response.body)['access_token']

    @valid_ct_blacklisted = QuicklinkService::Client.encode(@blacklisted_user.id.to_i, Time.now.to_i + (60 * 60 * 24 * 31 * 3), 'premium', Time.now.to_i)

    UserBlacklist.create!(
      user_id: @blacklisted_user.id,
      reason: 'Test blacklist'
    )

    # Invalid/expired access tokens
    @invalid_token = 'eyJhbGciOiJIUzI1NiJ9.eyJzdWILOjQ6LCJleHAiOjE2OTgxNzk0MjgsImp0aSI6IjQ1NDMyZWUyNWE4YWUyMjc1ZGY0YTE2ZTNlNmQ0YTY4IiwiaWF0IjoxNjk4MTY1MDI4LCJpc3MiOiJDQl9TdXJmYWNlUHJvOCJ9.nqGgQ6Z52CbaHZzPGcwQG6U-nMDxb1yIe7HQMxjoDTs'
    @invalid_client_token = 'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOjEsImV4adw6MTcwNzkzMzk5NSwidHlwIjoicHJlbWl1bSIsImlhdCI6MTcwNTI1NTY4MiwiaXNzIjoibWFua2RlIn0.25S1QuOifV7BUgilcqWaOK3UmZ1toPfdobi9z8m-b2o'
    # OWN JOBS & APPLIED JOBS
    # Create own jobs for valid verified user (valid_user_has_own_jobs) and applied jobs for valid verified user (valid_user_has_applied)
    5.times do
      job = Job.create!(
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
        activity_status: 1,
        job_status: 'listed',
        currency: 'CHF',
        job_type: 'Retail',
        job_type_value: '1'
      )
      application = Application.create!(
        user_id: @valid_user_has_applied.id,
        job_id: job.id,
        application_text: 'TestUpcomingApplicationText',
        response: 'No response yet ...'
      )
      application.accept('ACCEPTED')
    end

    @valid_request_token = QuicklinkService::Request::Encoder.call({ user_id: @valid_user_has_own_jobs.id, subscription_type: 'enterprise_1', mode: 'job', job_slug: @job.job_slug })
    @unlisted_request_token = QuicklinkService::Request::Encoder.call({ user_id: @valid_user_has_own_jobs.id, subscription_type: 'enterprise_1', mode: 'job', job_slug: @unlisted_job.job_slug })
    @archived_request_token = QuicklinkService::Request::Encoder.call({ user_id: @valid_user_has_own_jobs.id, subscription_type: 'enterprise_1', mode: 'job', job_slug: @archived_job.job_slug })
    @deactivated_request_token = QuicklinkService::Request::Encoder.call({ user_id: @valid_user_has_own_jobs.id, subscription_type: 'enterprise_1', mode: 'job', job_slug: @inactive_job.job_slug })
    @unsubscribed_request_token = QuicklinkService::Request::Encoder.call({ user_id: @unsubscribed_user.id, subscription_type: 'enterprise_1', mode: 'job', job_slug: @job.job_slug })
    @expired_request_token = QuicklinkService::Request.encode(@valid_user_exp.id, Time.now.to_i,
                                                              { user_id: @valid_user_exp.id, subscription_type: 'enterprise_1', mode: 'job', job_slug: @job.job_slug }, Time.now.to_i)
    @premium_request_token = QuicklinkService::Request::Encoder.call({ user_id: @user_premium.id, subscription_type: 'premium', mode: 'job', job_slug: @job.job_slug })
    @basic_request_token = QuicklinkService::Request::Encoder.call({ user_id: @user_basic.id, subscription_type: 'basic', mode: 'job', job_slug: @job.job_slug })
    @new_job_request_token = QuicklinkService::Request::Encoder.call({ user_id: @valid_user.id, subscription_type: 'basic', mode: 'job', job_slug: 'new-job-slug' })
    @blacklisted_request_token = QuicklinkService::Request::Encoder.call({ user_id: @blacklisted_user.id, subscription_type: 'basic', mode: 'job', job_slug: 'new-job-slug' })
    @not_found_request_token = QuicklinkService::Request.encode(0, Time.now.to_i, { user_id: @valid_user_exp.id, subscription_type: 'enterprise_1', mode: 'job', job_slug: @job.job_slug },
                                                                Time.now.to_i)
  end

  describe 'Quicklink', type: :request do
    describe '(POST: /api/v0/auth/token/client)' do
      context 'valid normal inputs' do
        it 'returns [200 Ok] and new client token' do
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_access_token }
          post('/api/v0/auth/token/client', headers:)
          expect(response).to have_http_status(200)
        end
        it 'returns [200 OK] for user with soon expiring subscription' do
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_at_exp }
          post('/api/v0/auth/token/client', headers:)
          expect(response).to have_http_status(200)
        end
      end
      context 'invalid inputs' do
        it 'returns [400 Bad Request] for missing access token in header' do
          post '/api/v0/auth/token/client'
          expect(response).to have_http_status(400)
        end
        it 'returns [401 Unauthorized] for expired/invalid access token' do
          headers = { 'HTTP_ACCESS_TOKEN' => @invalid_token }
          post('/api/v0/auth/token/client', headers:)
          expect(response).to have_http_status(401)
        end
        it 'returns [403 Forbidden] for user without active subscription' do
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_at_unsubscribed }
          post('/api/v0/auth/token/client', headers:)
          expect(response).to have_http_status(403)
        end
        it 'returns [403 Forbidden] for blacklisted user' do
          headers = { 'HTTP_ACCESS_TOKEN' => @valid_at_blacklisted }
          post('/api/v0/auth/token/client', headers:)
          expect(response).to have_http_status(403)
        end
      end
    end

    describe '(POST: /api/v0/sdk/request/auth/token)' do
      let(:request_body) do
        {
          mode: 'job',
          success_url: '/success',
          cancel_url: '/failure',
          job_slug: 'job#1'
        }
      end
      context 'valid normal inputs' do
        it 'returns [200 Ok] and new request token' do
          headers = { 'HTTP_CLIENT_TOKEN' => @valid_ct_has_own_jobs }
          post('/api/v0/sdk/request/auth/token', params: request_body, headers:)
          expect(response).to have_http_status(200)
        end
        it 'returns [200 Ok] and new request token' do
          headers = { 'HTTP_CLIENT_TOKEN' => @valid_ct_has_own_jobs }
          post('/api/v0/sdk/request/auth/token', params: request_body, headers:)
          expect(response).to have_http_status(200)
        end
        it 'returns [200 Ok] and new request token' do
          headers = { 'HTTP_CLIENT_TOKEN' => @valid_ct_has_own_jobs }
          post('/api/v0/sdk/request/auth/token', params: request_body.except(:success_url, :cancel_url), headers:)
          expect(response).to have_http_status(200)
        end
      end
      context 'invalid inputs' do
        it 'returns [400 Bad Request] for missing client token in header' do
          post '/api/v0/sdk/request/auth/token', params: request_body
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for invalid mode' do
          headers = { 'HTTP_CLIENT_TOKEN' => @valid_ct_has_own_jobs }
          invalid_request_body = request_body.merge(mode: 'invalid_mode')
          post('/api/v0/sdk/request/auth/token', params: invalid_request_body, headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for missing job_slug' do
          headers = { 'HTTP_CLIENT_TOKEN' => @valid_ct_has_own_jobs }
          post('/api/v0/sdk/request/auth/token', params: request_body.except(:job_slug), headers:)
          expect(response).to have_http_status(400)
        end
        it 'returns [401 Unauthorized] for expired/invalid client token' do
          headers = { 'HTTP_CLIENT_TOKEN' => @invalid_client_token }
          post('/api/v0/sdk/request/auth/token', params: request_body, headers:)
          expect(response).to have_http_status(401)
        end
        it 'returns [403 Forbidden] for blacklisted user' do
          headers = { 'HTTP_CLIENT_TOKEN' => @valid_ct_blacklisted }
          post('/api/v0/sdk/request/auth/token', params: request_body, headers:)
          expect(response).to have_http_status(403)
        end
      end
    end

    describe '(POST: /api/v0/sdk/request/handle)' do
      context 'valid normal inputs' do
        it 'returns [200 Ok] and creates session' do
          post('/api/v0/sdk/request/handle', headers: { 'HTTP_ACCESS_TOKEN' => @valid_access_token, 'HTTP_REQUEST_TOKEN' => @valid_request_token })
          expect(response).to have_http_status(200)
        end
      end
      context 'invalid inputs' do
        it 'returns [400 Bad Request] for missing access token in header' do
          post('/api/v0/sdk/request/handle', headers: { 'HTTP_REQUEST_TOKEN' => @valid_request_token })
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for missing request token in header' do
          post('/api/v0/sdk/request/handle', headers: { 'HTTP_ACCESS_TOKEN' => @valid_access_token })
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for missing both access and request token in header' do
          post('/api/v0/sdk/request/handle')
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for deactivated posting' do
          post('/api/v0/sdk/request/handle', headers: { 'HTTP_ACCESS_TOKEN' => @valid_access_token, 'HTTP_REQUEST_TOKEN' => @deactivated_request_token })
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for archived posting' do
          post('/api/v0/sdk/request/handle', headers: { 'HTTP_ACCESS_TOKEN' => @valid_access_token, 'HTTP_REQUEST_TOKEN' => @archived_request_token })
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for deactivated posting' do
          post('/api/v0/sdk/request/handle', headers: { 'HTTP_ACCESS_TOKEN' => @valid_access_token, 'HTTP_REQUEST_TOKEN' => @deactivated_request_token })
          expect(response).to have_http_status(400)
        end
        it 'returns [401 Unauthorized] for expired/invalid access token' do
          post('/api/v0/sdk/request/handle', headers: { 'HTTP_ACCESS_TOKEN' => @invalid_token, 'HTTP_REQUEST_TOKEN' => @valid_request_token })
          expect(response).to have_http_status(401)
        end
        it 'returns [401 Unauthorized] for expired/invalid request token' do
          post('/api/v0/sdk/request/handle', headers: { 'HTTP_ACCESS_TOKEN' => @valid_access_token, 'HTTP_REQUEST_TOKEN' => @invalid_token })
          expect(response).to have_http_status(401)
        end
        it 'returns [401 Unauthorized] for request token with expired subscription' do
          post('/api/v0/sdk/request/handle', headers: { 'HTTP_ACCESS_TOKEN' => @valid_access_token, 'HTTP_REQUEST_TOKEN' => @expired_request_token })
          expect(response).to have_http_status(401)
        end
        it 'returns [401 Unauthorized] for not existing client' do
          post('/api/v0/sdk/request/handle', headers: { 'HTTP_ACCESS_TOKEN' => @not_found_request_token })
          expect(response).to have_http_status(401)
        end
        it 'returns [403 Forbidden] for blacklisted user' do
          post('/api/v0/sdk/request/handle', headers: { 'HTTP_ACCESS_TOKEN' => @valid_at_blacklisted })
          expect(response).to have_http_status(403)
        end
        it 'returns [403 Forbidden] for request token with invalid subscription' do
          post('/api/v0/sdk/request/handle', headers: { 'HTTP_ACCESS_TOKEN' => @valid_access_token, 'HTTP_REQUEST_TOKEN' => @unsubscribed_request_token })
          expect(response).to have_http_status(403)
        end
        it 'returns [403 Forbidden] if user creates job with cancelled subscription' do
          @user_basic.payment_processor.subscription.cancel_now!
          post('/api/v0/sdk/request/handle', headers: { 'HTTP_ACCESS_TOKEN' => @valid_access_token, 'HTTP_REQUEST_TOKEN' => @basic_request_token })
          expect(response).to have_http_status(403)
        end
        it 'returns [403 Forbidden] if user creates job with cancelled subscription' do
          @user_premium.payment_processor.subscription.cancel_now!
          post('/api/v0/sdk/request/handle', headers: { 'HTTP_ACCESS_TOKEN' => @valid_access_token, 'HTTP_REQUEST_TOKEN' => @premium_request_token })
          expect(response).to have_http_status(403)
        end
        it 'returns [429 Too Many Requests] if user creates job while having more jobs than what his subscription (basic) allows' do
          3.times do
            post('/api/v0/jobs', headers: { 'HTTP_ACCESS_TOKEN' => @basic_at })
            expect(response).to have_http_status(201)
          end
          post('/api/v0/sdk/request/handle', headers: { 'HTTP_ACCESS_TOKEN' => @valid_access_token, 'HTTP_REQUEST_TOKEN' => @basic_request_token })
          expect(response).to have_http_status(429)
        end
        it 'returns [429 Too Many Requests] if user creates job while having more jobs than what his subscription (premium) allows' do
          50.times do
            post('/api/v0/jobs', headers: { 'HTTP_ACCESS_TOKEN' => @premium_at })
            expect(response).to have_http_status(201)
          end
          post('/api/v0/sdk/request/handle', headers: { 'HTTP_ACCESS_TOKEN' => @valid_access_token, 'HTTP_REQUEST_TOKEN' => @premium_request_token })
          expect(response).to have_http_status(429)
        end
      end
    end

    describe '(POST: /api/v0/sdk/apply)' do
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
      let(:headers) { { 'HTTP_ACCESS_TOKEN' => @valid_access_token } }

      context 'valid normal inputs' do
        it 'returns [201 Created] and creates application' do
          post('/api/v0/sdk/apply', params: valid_attributes_basic, headers: { 'HTTP_ACCESS_TOKEN' => @valid_access_token, 'HTTP_REQUEST_TOKEN' => @valid_request_token })
          expect(response).to have_http_status(201)
        end
      end
      context 'invalid inputs' do
        it 'returns [400 Bad Request] for missing access token in header' do
          post('/api/v0/sdk/apply', params: valid_attributes_basic, headers: { 'HTTP_REQUEST_TOKEN' => @valid_request_token })
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for missing request token in header' do
          post('/api/v0/sdk/apply', params: valid_attributes_basic, headers: { 'HTTP_ACCESS_TOKEN' => @valid_access_token })
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for missing both access and request token in header' do
          post('/api/v0/sdk/apply')
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for deactivated posting' do
          post('/api/v0/sdk/apply', params: valid_attributes_basic, headers: { 'HTTP_ACCESS_TOKEN' => @valid_access_token, 'HTTP_REQUEST_TOKEN' => @deactivated_request_token })
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for archived posting' do
          post('/api/v0/sdk/apply', params: valid_attributes_basic, headers: { 'HTTP_ACCESS_TOKEN' => @valid_access_token, 'HTTP_REQUEST_TOKEN' => @archived_request_token })
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for deactivated posting' do
          post('/api/v0/sdk/apply', params: valid_attributes_basic, headers: { 'HTTP_ACCESS_TOKEN' => @valid_access_token, 'HTTP_REQUEST_TOKEN' => @deactivated_request_token })
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for invalid application' do
          post('/api/v0/sdk/apply', params: invalid_attributes_basic, headers: { 'HTTP_ACCESS_TOKEN' => @valid_access_token, 'HTTP_REQUEST_TOKEN' => @valid_request_token })
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for blank application' do
          post('/api/v0/sdk/apply', params: blank_attributes_basic, headers: { 'HTTP_ACCESS_TOKEN' => @valid_access_token, 'HTTP_REQUEST_TOKEN' => @valid_request_token })
          expect(response).to have_http_status(400)
        end
        it 'returns [401 Unauthorized] for expired/invalid access token' do
          post('/api/v0/sdk/apply', params: valid_attributes_basic, headers: { 'HTTP_ACCESS_TOKEN' => @invalid_token, 'HTTP_REQUEST_TOKEN' => @valid_request_token })
          expect(response).to have_http_status(401)
        end
        it 'returns [401 Unauthorized] for expired/invalid request token' do
          post('/api/v0/sdk/apply', params: valid_attributes_basic, headers: { 'HTTP_ACCESS_TOKEN' => @valid_access_token, 'HTTP_REQUEST_TOKEN' => @invalid_token })
          expect(response).to have_http_status(401)
        end
        it 'returns [401 Unauthorized] for request token with expired subscription' do
          post('/api/v0/sdk/apply', params: valid_attributes_basic, headers: { 'HTTP_ACCESS_TOKEN' => @valid_access_token, 'HTTP_REQUEST_TOKEN' => @expired_request_token })
          expect(response).to have_http_status(401)
        end
        it 'returns [401 Unauthorized] for not existing client' do
          post('/api/v0/sdk/apply', params: valid_attributes_basic, headers: { 'HTTP_ACCESS_TOKEN' => @not_found_request_token })
          expect(response).to have_http_status(401)
        end
        it 'returns [403 Forbidden] for blacklisted user' do
          post('/api/v0/sdk/apply', params: valid_attributes_basic, headers: { 'HTTP_ACCESS_TOKEN' => @valid_at_blacklisted })
          expect(response).to have_http_status(403)
        end
        it 'returns [403 Forbidden] for request token with invalid subscription' do
          post('/api/v0/sdk/apply', params: valid_attributes_basic, headers: { 'HTTP_ACCESS_TOKEN' => @valid_access_token, 'HTTP_REQUEST_TOKEN' => @unsubscribed_request_token })
          expect(response).to have_http_status(403)
        end
        it 'returns [403 Forbidden] if user creates job with cancelled subscription' do
          @user_basic.payment_processor.subscription.cancel_now!
          post('/api/v0/sdk/apply', params: valid_attributes_basic, headers: { 'HTTP_ACCESS_TOKEN' => @valid_access_token, 'HTTP_REQUEST_TOKEN' => @basic_request_token })
          expect(response).to have_http_status(403)
        end
        it 'returns [403 Forbidden] if user creates job with cancelled subscription' do
          @user_premium.payment_processor.subscription.cancel_now!
          post('/api/v0/sdk/apply', params: valid_attributes_basic, headers: { 'HTTP_ACCESS_TOKEN' => @valid_access_token, 'HTTP_REQUEST_TOKEN' => @premium_request_token })
          expect(response).to have_http_status(403)
        end
        it 'returns [429 Too Many Requests] if user creates job while having more jobs than what his subscription (basic) allows' do
          3.times do
            post('/api/v0/jobs', headers: { 'HTTP_ACCESS_TOKEN' => @basic_at })
            expect(response).to have_http_status(201)
          end
          post('/api/v0/sdk/apply', params: valid_attributes_basic, headers: { 'HTTP_ACCESS_TOKEN' => @valid_access_token, 'HTTP_REQUEST_TOKEN' => @basic_request_token })
          expect(response).to have_http_status(429)
        end
        it 'returns [429 Too Many Requests] if user creates job while having more jobs than what his subscription (premium) allows' do
          50.times do
            post('/api/v0/jobs', headers: { 'HTTP_ACCESS_TOKEN' => @premium_at })
            expect(response).to have_http_status(201)
          end
          post('/api/v0/sdk/apply', params: valid_attributes_basic, headers: { 'HTTP_ACCESS_TOKEN' => @valid_access_token, 'HTTP_REQUEST_TOKEN' => @premium_request_token })
          expect(response).to have_http_status(429)
        end
      end
    end
  end
end
