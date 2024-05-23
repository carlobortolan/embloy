# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'GeniusQueriesController' do
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
    @basic_job = Job.create!(
      user_id: @user_basic.id,
      activity_status: 1
    )

    # Create jobs
    @premium_job = Job.create!(
      user_id: @user_premium.id,
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

    # 200
    @valid_genius_query = URI.encode_www_form_component(GeniusQueryService::Encoder.call(@valid_user_has_own_jobs.id, { job_id: @job.id }))
    @unlisted_genius_query = URI.encode_www_form_component(GeniusQueryService::Encoder.call(@valid_user_has_own_jobs.id, { job_id: @unlisted_job.id }))
    @archived_genius_query = URI.encode_www_form_component(GeniusQueryService::Encoder.call(@valid_user_has_own_jobs.id, { job_id: @archived_job.id }))
    # 400 & 401
    @expired_genius_query = URI.encode_www_form_component(GeniusQueryService.encode(@valid_user.id, Time.now.to_i - 1.second, AuthenticationTokenService::Refresh.jti(Time.now.to_i), Time.now.to_i, { job_id: @basic_job.id }).gsub(
                                                            '.', '°'
                                                          ))
    @invalid_genius_query = URI.encode_www_form_component('eyJhbGciOiJIUzI1NiJ9°eyJzdWIiOjEsImV4cCI6MTcwNzk0Mjc1OSwianRpIjoiMWRjZWE3ZDE0Y2QxNGYyYmNjZjkyODljN2E3YmQ5NDYiLCJpYXQiOjE3MDc4NTYzNTksImpvYl9pZCI6IjIiLCJpc3MiOiJhcGkuZW1ibG95LmNvbSJ9°CQsVw7EhwlAQLC6jtCbdou81qbiVSWgMhW43SXqbaG0')
    # 403
    @blacklisted_genius_query = URI.encode_www_form_component(GeniusQueryService::Encoder.call(@blacklisted_user.id, { job_id: @not_owned_job.id }))
    @basic_genius_query = URI.encode_www_form_component(GeniusQueryService::Encoder.call(@user_basic.id, { job_id: @basic_job.id }))
    @premium_genius_query = URI.encode_www_form_component(GeniusQueryService::Encoder.call(@user_premium.id, { job_id: @premium_job.id }))
    # 404
    @not_found_genius_query = URI.encode_www_form_component(GeniusQueryService.encode(@valid_user.id, Time.now.to_i + 1.day, AuthenticationTokenService::Refresh.jti(Time.now.to_i), Time.now.to_i, { job_id: 0 }).gsub(
                                                              '.', '°'
                                                            ))
    # 409
    @deactivated_genius_query = URI.encode_www_form_component(GeniusQueryService::Encoder.call(@valid_user_has_own_jobs.id, { job_id: @inactive_job.id }))

    UserBlacklist.create!(
      user_id: @blacklisted_user.id,
      reason: 'Test blacklist'
    )
    # Invalid/expired access tokens
    @invalid_token = 'eyJhbGciOiJIUzI1NiJ9.eyJzdWILOjQ6LCJleHAiOjE2OTgxNzk0MjgsImp0aSI6IjQ1NDMyZWUyNWE4YWUyMjc1ZGY0YTE2ZTNlNmQ0YTY4IiwiaWF0IjoxNjk4MTY1MDI4LCJpc3MiOiJDQl9TdXJmYWNlUHJvOCJ9.nqGgQ6Z52CbaHZzPGcwQG6U-nMDxb1yIe7HQMxjoDTs'
  end

  describe '(POST: /api/v0/resource)' do
    context 'valid normal inputs' do
      it 'returns [200 OK] and creates genius query' do
        post("/api/v0/resource?job_id=#{@job.id.to_i}", headers: { 'HTTP_ACCESS_TOKEN' => @valid_at_has_own_jobs })
        expect(response).to have_http_status(200)
      end
      it 'returns [200 OK] and creates genius query with custom expiration date' do
        post("/api/v0/resource?job_id=#{@job.id.to_i}&exp=#{Time.now + 1.day}", headers: { 'HTTP_ACCESS_TOKEN' => @valid_at_has_own_jobs })
        expect(response).to have_http_status(200)
      end
      it 'returns [200 OK] for archived posting' do
        post("/api/v0/resource?job_id=#{@archived_job.id.to_i}", headers: { 'HTTP_ACCESS_TOKEN' => @valid_at_has_own_jobs })
        expect(response).to have_http_status(200)
      end
    end
    context 'invalid inputs' do
      it 'returns [400 Bad Request] for missing access token in header' do
        post('/api/v0/resource')
        expect(response).to have_http_status(400)
      end
      it 'returns [400 Bad Request] for missing resource id' do
        post('/api/v0/resource', headers: { 'HTTP_ACCESS_TOKEN' => @valid_access_token })
        expect(response).to have_http_status(400)
      end
      it 'returns [400 Bad Request] and creates genius query with invalid custom expiration date' do
        post("/api/v0/resource?job_id=#{@job.id.to_i}&exp=#{Time.now + 10.years}", headers: { 'HTTP_ACCESS_TOKEN' => @valid_at_has_own_jobs })
        expect(response).to have_http_status(400)
      end
      it 'returns [400 Bad Request] and creates genius query with invalid custom expiration date' do
        post("/api/v0/resource?job_id=#{@job.id.to_i}&exp=-10", headers: { 'HTTP_ACCESS_TOKEN' => @valid_at_has_own_jobs })
        expect(response).to have_http_status(400)
      end
      it 'returns [400 Bad Request] and creates genius query with custom expiration date in the past' do
        post("/api/v0/resource?job_id=#{@job.id.to_i}&exp=#{Time.now - 1.second}", headers: { 'HTTP_ACCESS_TOKEN' => @valid_at_has_own_jobs })
        expect(response).to have_http_status(400)
      end
      it 'returns [401 Unauthorized] for expired/invalid access token' do
        post("/api/v0/resource?job_id=#{@job.id.to_i}", headers: { 'HTTP_ACCESS_TOKEN' => @invalid_token })
        expect(response).to have_http_status(401)
      end
      it 'returns [403 Forbidden] for deactivated posting' do
        post("/api/v0/resource?job_id=#{@inactive_job.id.to_i}", headers: { 'HTTP_ACCESS_TOKEN' => @valid_at_has_own_jobs })
        expect(response).to have_http_status(403)
      end
      it 'returns [403 Forbidden] for blacklisted user' do
        post("/api/v0/resource?job_id=#{@not_owned_job.id.to_i}", headers: { 'HTTP_ACCESS_TOKEN' => @valid_at_blacklisted })
        expect(response).to have_http_status(403)
      end
      it 'returns [403 Forbidden] for user with invalid subscription' do
        post("/api/v0/resource?job_id=#{@job.id.to_i}", headers: { 'HTTP_ACCESS_TOKEN' => @valid_at_unsubscribed })
        expect(response).to have_http_status(403)
      end
      it 'returns [403 Forbidden] if user creates genius query for not owned job' do
        post("/api/v0/resource?job_id=#{@not_owned_job.id.to_i}", headers: { 'HTTP_ACCESS_TOKEN' => @basic_at })
        expect(response).to have_http_status(403)
      end
      it 'returns [403 Forbidden] if user creates genius query with cancelled subscription' do
        @user_basic.payment_processor.subscription.cancel_now!
        post("/api/v0/resource?job_id=#{@basic_job.id.to_i}", headers: { 'HTTP_ACCESS_TOKEN' => @basic_at })
        expect(response).to have_http_status(403)
      end
      it 'returns [403 Forbidden] if user creates genius query with cancelled subscription' do
        @user_premium.payment_processor.subscription.cancel_now!
        post("/api/v0/resource?job_id=#{@premium_job.id.to_i}", headers: { 'HTTP_ACCESS_TOKEN' => @premium_at })
        expect(response).to have_http_status(403)
      end
      it 'returns [404 Not Found] if job does not exist' do
        post('/api/v0/resource?job_id=0', headers: { 'HTTP_ACCESS_TOKEN' => @premium_at })
        expect(response).to have_http_status(404)
      end
    end
  end
  describe '(GET: /api/v0/resource/[:query])' do
    context 'valid normal inputs' do
      it 'returns [200 OK] and returns resource' do
        get("/api/v0/resource/#{@valid_genius_query}")
        expect(response).to have_http_status(200)
      end
      it 'returns [200 OK] and returns resource' do
        get("/api/v0/resource/#{@basic_genius_query}")
        expect(response).to have_http_status(200)
      end
      it 'returns [200 OK] and returns resource' do
        get("/api/v0/resource/#{@premium_genius_query}")
        expect(response).to have_http_status(200)
      end
      it 'returns [200 OK] and returns resource even if unlisted' do
        get("/api/v0/resource/#{@unlisted_genius_query}")
        expect(response).to have_http_status(200)
      end
    end
    context 'invalid inputs' do
      it 'returns [400 Bad Request] for empty query' do
        get('/api/v0/resource')
        expect(response).to have_http_status(400)
      end
      it 'returns [400 Bad Request] for invalid query' do
        get("/api/v0/resource/#{@invalid_genius_query}")
        expect(response).to have_http_status(400)
      end
      it 'returns [400 Bad Request] if query is expired' do
        get("/api/v0/resource/#{@expired_genius_query}")
        expect(response).to have_http_status(400)
      end
      it 'returns [403 Forbidden] for blacklisted owner' do
        get("/api/v0/resource/#{@blacklisted_genius_query}")
        expect(response).to have_http_status(403)
      end
      it 'returns [403 Forbidden] if resource owner has cancelled subscription' do
        @user_basic.payment_processor.subscription.cancel_now!
        get("/api/v0/resource/#{@basic_genius_query}")
        expect(response).to have_http_status(403)
      end
      it 'returns [403 Forbidden] if resource owner has cancelled subscription' do
        @user_premium.payment_processor.subscription.cancel_now!
        get("/api/v0/resource/#{@premium_genius_query}")
        expect(response).to have_http_status(403)
      end
      it 'returns [404 Not Found] if resource does not exist' do
        get("/api/v0/resource/#{@not_found_genius_query}")
        expect(response).to have_http_status(404)
      end
      it 'returns [409 Conflict] and returns resource even if archived' do
        get("/api/v0/resource/#{@archived_genius_query}")
        expect(response).to have_http_status(409)
      end
      it 'returns [409 Conflict] if resource has been deactivated' do
        get("/api/v0/resource/#{@deactivated_genius_query}")
        expect(response).to have_http_status(409)
      end
    end
  end
end
