# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'CompanyController' do
  before(:all) do
    charset = ('a'..'z').to_a + ('A'..'Z').to_a

    ### NORMAL USER CREATION ###

    # Create valid verified user without own jobs, upcoming jobs, reviews, ...
    @unsubscribed_user = User.create!(
      first_name: 'Max',
      last_name: 'Mustermann',
      email: "#{(0...16).map { charset.sample }.join}@embloy.com",
      password: 'password',
      password_confirmation: 'password',
      user_role: 'verified',
      activity_status: 1
    )

    # Create valid verified user with own jobs
    @subscribed_user = User.create!(
      first_name: 'Max',
      last_name: 'Mustermann',
      email: "#{(0...16).map { charset.sample }.join}@embloy.com",
      password: 'password',
      password_confirmation: 'password',
      user_role: 'verified',
      activity_status: 1
    )
    @subscribed_user.set_payment_processor :fake_processor, allow_fake: true
    @subscribed_user.pay_customers
    @subscribed_user.payment_processor.customer
    @subscribed_user.payment_processor.charge(19_00)
    @subscribed_user.payment_processor.subscribe(plan: 'price_1OUuWFKMiBrigNb6lfAf7ptj')

    ### COMPANY USER CREATION ###

    # Create valid verified company with own jobs
    @valid_company_has_own_jobs = CompanyUser.create!(
      first_name: 'Max',
      last_name: 'Mustermann',
      email: "#{(0...16).map { charset.sample }.join}@embloy.com",
      password: 'password',
      password_confirmation: 'password',
      user_role: 'verified',
      activity_status: 1,
      company_name: 'Test Company',
      company_description: 'Test Description',
      company_urls: ['https://www.example.com', 'https://www.linkedin.com/company/example'],
      company_industry: 'Test Industry',
      company_email: "#{(0...16).map { charset.sample }.join}@embloy.com",
      company_phone: 'Test Email'
    )

    @valid_company_has_own_jobs.set_payment_processor :fake_processor, allow_fake: true
    @valid_company_has_own_jobs.pay_customers
    @valid_company_has_own_jobs.payment_processor.customer
    @valid_company_has_own_jobs.payment_processor.charge(19_00)
    @valid_company_has_own_jobs.payment_processor.subscribe(plan: 'price_1OUuWFKMiBrigNb6lfAf7ptj')

    # Create valid verified company without jobs
    @valid_company = CompanyUser.create!(
      first_name: 'Max',
      last_name: 'Mustermann',
      email: "#{(0...16).map { charset.sample }.join}@embloy.com",
      password: 'password',
      password_confirmation: 'password',
      user_role: 'verified',
      activity_status: 1,
      company_name: 'Test Company',
      company_description: 'Test Description',
      company_urls: ['https://www.example.com', 'https://www.linkedin.com/company/example'],
      company_industry: 'Test Industry',
      company_email: "#{(0...16).map { charset.sample }.join}@embloy.com",
      company_phone: 'Test Email'
    )
    @valid_company.set_payment_processor :fake_processor, allow_fake: true
    @valid_company.pay_customers
    @valid_company.payment_processor.customer
    @valid_company.payment_processor.charge(19_00)
    @valid_company.payment_processor.subscribe(plan: 'price_1OUuWFKMiBrigNb6lfAf7ptj')

    @unsuscribed_company = CompanyUser.create!(
      first_name: 'Max',
      last_name: 'Mustermann',
      email: "#{(0...16).map { charset.sample }.join}@embloy.com",
      password: 'password',
      password_confirmation: 'password',
      user_role: 'verified',
      activity_status: 1,
      company_name: 'Test Company',
      company_description: 'Test Description',
      company_urls: ['https://www.example.com', 'https://www.linkedin.com/company/example'],
      company_industry: 'Test Industry',
      company_email: "#{(0...16).map { charset.sample }.join}@embloy.com",
      company_phone: 'Test Email'
    )

    # Create valid unverified user
    @unverified_company = CompanyUser.create!(
      first_name: 'Max',
      last_name: 'Mustermann',
      email: "#{(0...16).map { charset.sample }.join}@embloy.com",
      password: 'password',
      password_confirmation: 'password',
      user_role: 'spectator',
      activity_status: 0,
      company_name: 'Test Company',
      company_description: 'Test Description',
      company_urls: ['https://www.example.com', 'https://www.linkedin.com/company/example'],
      company_industry: 'Test Industry',
      company_email: "#{(0...16).map { charset.sample }.join}@embloy.com",
      company_phone: 'Test Email'
    )

    # Blacklisted verified user
    @blacklisted_company = CompanyUser.create!(
      first_name: 'Max',
      last_name: 'Mustermann',
      email: "#{(0...16).map { charset.sample }.join}@embloy.com",
      password: 'password',
      password_confirmation: 'password',
      user_role: 'verified',
      activity_status: 1,
      company_name: 'Test Company',
      company_description: 'Test Description',
      company_urls: ['https://www.example.com', 'https://www.linkedin.com/company/example'],
      company_industry: 'Test Industry',
      company_email: "#{(0...16).map { charset.sample }.join}@embloy.com",
      company_phone: 'Test Email'
    )

    UserBlacklist.create!(
      user_id: @blacklisted_company.id,
      reason: 'Test blacklist'
    )

    ### COMPANY JOBS
    @listed_job = Job.create!(
      user_id: @valid_company_has_own_jobs.id,
      job_status: :listed
    )

    @inactive_job = Job.create!(
      user_id: @valid_company_has_own_jobs.id,
      activity_status: 0
    )

    @archived_job = Job.create!(
      user_id: @valid_company_has_own_jobs.id,
      job_status: :archived
    )

    @unlisted_job = Job.create!(
      user_id: @valid_company_has_own_jobs.id,
      job_status: :unlisted
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

    # Company user refresh/access tokens
    credentials = Base64.strict_encode64("#{@valid_company.email}:password")
    headers = { 'Authorization' => "Basic #{credentials}" }
    post('/api/v0/auth/token/refresh', headers:)
    @company_refresh_token = JSON.parse(response.body)['refresh_token']

    params = { 'grant_type' => 'refresh_token', 'refresh_token' => @company_refresh_token }
    post('/api/v0/auth/token/access', params:)
    @company_access_token = JSON.parse(response.body)['access_token']

    # Unsubscribed company user refresh/access tokens
    credentials = Base64.strict_encode64("#{@unsuscribed_company.email}:password")
    headers = { 'Authorization' => "Basic #{credentials}" }
    post('/api/v0/auth/token/refresh', headers:)
    @unsubscribed_company_rt = JSON.parse(response.body)['refresh_token']

    params = { 'grant_type' => 'refresh_token', 'refresh_token' => @unsubscribed_company_rt }
    post('/api/v0/auth/token/access', params:)
    @unsubscribed_company_at = JSON.parse(response.body)['access_token']

    # Subscribed user refresh/access tokens
    credentials = Base64.strict_encode64("#{@subscribed_user.email}:password")
    headers = { 'Authorization' => "Basic #{credentials}" }
    post('/api/v0/auth/token/refresh', headers:)
    @subscribed_refresh_token = JSON.parse(response.body)['refresh_token']

    params = { 'grant_type' => 'refresh_token', 'refresh_token' => @subscribed_refresh_token }
    post('/api/v0/auth/token/access', params:)
    @subscribed_access_token = JSON.parse(response.body)['access_token']

    # Unsubscribed user refresh/access tokens
    credentials = Base64.strict_encode64("#{@unsubscribed_user.email}:password")
    headers = { 'Authorization' => "Basic #{credentials}" }
    post('/api/v0/auth/token/refresh', headers:)
    @unsubscribed_refresh_token = JSON.parse(response.body)['refresh_token']

    params = { 'grant_type' => 'refresh_token', 'refresh_token' => @unsubscribed_refresh_token }
    post('/api/v0/auth/token/access', params:)
    @unsubscribed_access_token = JSON.parse(response.body)['access_token']

    # Blacklisted user refresh/access/client tokens
    credentials = Base64.strict_encode64("#{@blacklisted_user.email}:password")
    headers = { 'Authorization' => "Basic #{credentials}" }
    post('/api/v0/auth/token/refresh', headers:)
    @valid_rt_blacklisted = JSON.parse(response.body)['refresh_token']

    params = { 'grant_type' => 'refresh_token', 'refresh_token' => @valid_rt_blacklisted }
    post('/api/v0/auth/token/access', params:)
    @valid_at_blacklisted = JSON.parse(response.body)['access_token']

    UserBlacklist.create!(
      user_id: @blacklisted_user.id,
      reason: 'Test blacklist'
    )

    # Invalid/expired access tokens
    @invalid_access_token = 'eyJhbGciOiJIUzI1NiJ9.eyJzdWILOjQ6LCJleHAiOjE2OTgxNzk0MjgsImp0aSI6IjQ1NDMyZWUyNWE4YWUyMjc1ZGY0YTE2ZTNlNmQ0YTY4IiwiaWF0IjoxNjk4MTY1MDI4LCJpc3MiOiJDQl9TdXJmYWNlUHJvOCJ9.nqGgQ6Z52CbaHZzPGcwQG6U-nMDxb1yIe7HQMxjoDTs'
  end

  describe '(GET: /api/v0/company/:id/board)' do
    context 'valid normal inputs' do
      it 'returns [200 Ok] and job JSONs if company has own jobs' do
        get("/api/v0/company/#{@valid_company_has_own_jobs.company_slug}/board")
        expect(response).to have_http_status(200)
      end
      it 'returns [200 Ok] and job JSONs if company has no jobs' do
        get("/api/v0/company/#{@valid_company.company_slug}/board")
        expect(response).to have_http_status(204)
      end
    end
    context 'invalid inputs' do
      it 'returns [403 Forbidden] for blacklisted company' do
        get("/api/v0/company/#{@blacklisted_company.company_slug}/board")
        expect(response).to have_http_status(403)
      end
      it 'returns [403 Forbidden] for unverified company' do
        get("/api/v0/company/#{@unverified_company.company_slug}/board")
        expect(response).to have_http_status(403)
      end
      it 'returns [403 Forbidden] for company without active subscription' do
        get("/api/v0/company/#{@unsuscribed_company.company_slug}/board")
        expect(response).to have_http_status(403)
      end
      it 'returns [404 Not Found] for non-existent company' do
        get('/api/v0/company/non-existing/board')
        expect(response).to have_http_status(404)
      end
    end
  end

  describe '(GET: /api/v0/company/:id/board/:job_slug)' do
    context 'valid normal inputs' do
      it 'returns [200 Ok] and job JSONs if company has own jobs' do
        get("/api/v0/company/#{@valid_company_has_own_jobs.company_slug}/board/#{@listed_job.job_slug}")
        expect(response).to have_http_status(200)
      end
    end
    context 'invalid inputs' do
      it 'returns [403 Forbidden] for blacklisted company' do
        get("/api/v0/company/#{@blacklisted_company.company_slug}/board/#{@listed_job.job_slug}")
        expect(response).to have_http_status(403)
      end
      it 'returns [403 Forbidden] for unverified company' do
        get("/api/v0/company/#{@unverified_company.company_slug}/board/#{@listed_job.job_slug}")
        expect(response).to have_http_status(403)
      end
      it 'returns [403 Forbidden] for company without active subscription' do
        get("/api/v0/company/#{@unsuscribed_company.company_slug}/board/#{@listed_job.job_slug}")
        expect(response).to have_http_status(403)
      end
      it 'returns [404 Not Found] for non existing job' do
        get("/api/v0/company/#{@valid_company_has_own_jobs.company_slug}/board/non_existing_job_slug")
        expect(response).to have_http_status(404)
      end
      it 'returns [409 Conflict] for unlisted job' do
        get("/api/v0/company/#{@valid_company_has_own_jobs.company_slug}/board/#{@unlisted_job.job_slug}")
        expect(response).to have_http_status(409)
      end
      it 'returns [409 Conflict] for archived job' do
        get("/api/v0/company/#{@valid_company_has_own_jobs.company_slug}/board/#{@archived_job.job_slug}")
        expect(response).to have_http_status(409)
      end
      it 'returns [409 Conflict] for inactive job' do
        get("/api/v0/company/#{@valid_company_has_own_jobs.company_slug}/board/#{@inactive_job.job_slug}")
        expect(response).to have_http_status(409)
      end
    end
  end

  describe '(GET: /api/v0/company/:id)' do
    context 'valid normal inputs' do
      it 'returns [200 Ok] and company JSON' do
        headers = { 'Authorization' => "Bearer #{@unsubscribed_access_token}" }
        get("/api/v0/company/#{@valid_company.id.to_i}", headers:)
        expect(response).to have_http_status(200)
      end
    end
    context 'invalid inputs' do
      it 'returns [400 Bad Request] for missing access token in header' do
        get("/api/v0/company/#{@valid_company.id.to_i}")
        expect(response).to have_http_status(400)
      end
      it 'returns [401 Unauthorized] for expired/invalid access token' do
        headers = { 'Authorization' => "Bearer #{@invalid_access_token}" }
        get("/api/v0/company/#{@valid_company.id.to_i}", headers:)
        expect(response).to have_http_status(401)
      end
      it 'returns [403 Forbidden] for blacklisted user' do
        headers = { 'Authorization' => "Bearer #{@valid_at_blacklisted}" }
        get("/api/v0/company/#{@valid_company.id.to_i}", headers:)
        expect(response).to have_http_status(403)
      end
      it 'returns [403 Forbidden] for blacklisted company' do
        headers = { 'Authorization' => "Bearer #{@unsubscribed_access_token}" }
        get("/api/v0/company/#{@blacklisted_company.id.to_i}", headers:)
        expect(response).to have_http_status(403)
      end
      it 'returns [403 Forbidden] for unverified company' do
        headers = { 'Authorization' => "Bearer #{@unsubscribed_access_token}" }
        get("/api/v0/company/#{@unverified_company.id.to_i}", headers:)
        expect(response).to have_http_status(403)
      end
      it 'returns [403 Forbidden] for unsubscribed company' do
        headers = { 'Authorization' => "Bearer #{@unsubscribed_access_token}" }
        get("/api/v0/company/#{@unsuscribed_company.id.to_i}", headers:)
        expect(response).to have_http_status(403)
      end
    end
  end

  describe '(DELETE: /api/v0/company/:id)' do
    context 'valid normal inputs' do
      it 'returns [200 Ok] and deletes company' do
        headers = { 'Authorization' => "Bearer #{@company_access_token}" }
        delete("/api/v0/company/#{@valid_company.id.to_i}", headers:)
        expect(response).to have_http_status(200)
      end
    end
    context 'invalid inputs' do
      it 'returns [400 Bad Request] for missing access token in header' do
        delete("/api/v0/company/#{@valid_company.id.to_i}")
        expect(response).to have_http_status(400)
      end
      it 'returns [401 Unauthorized] for expired/invalid access token' do
        headers = { 'Authorization' => "Bearer #{@invalid_access_token}" }
        delete("/api/v0/company/#{@valid_company.id.to_i}", headers:)
        expect(response).to have_http_status(401)
      end
      it 'returns [403 Forbidden] for blacklisted user' do
        headers = { 'Authorization' => "Bearer #{@valid_at_blacklisted}" }
        delete("/api/v0/company/#{@blacklisted_user.id.to_i}", headers:)
        expect(response).to have_http_status(403)
      end
      it 'returns [403 Forbidden] for trying to delete not own company' do
        headers = { 'Authorization' => "Bearer #{@subscribed_access_token}" }
        delete("/api/v0/company/#{@valid_company.id.to_i}", headers:)
        expect(response).to have_http_status(403)
      end
      it 'returns [403 Forbidden] for unsubscribed company' do
        headers = { 'Authorization' => "Bearer #{@unsubscribed_company_at}" }
        delete("/api/v0/company/#{@unsuscribed_company.id.to_i}", headers:)
        expect(response).to have_http_status(403)
      end
      it 'returns [404 Not Found] for non existing company' do
        headers = { 'Authorization' => "Bearer #{@company_access_token}" }
        delete('/api/v0/company/not-a-real-company', headers:)
        expect(response).to have_http_status(404)
      end
      it 'returns [404 Not Found] for non existing company' do
        headers = { 'Authorization' => "Bearer #{@company_access_token}" }
        delete("/api/v0/company/#{@subscribed_user.id.to_i}", headers:)
        expect(response).to have_http_status(404)
      end
    end
  end

  describe '(POST: /api/v0/company)' do
    pending "POST:/company specs not implemented yet: #{__FILE__}"
  end

  describe '(PATCH: /api/v0/company/:id)' do
    pending "PATCH:/company/:id specs not implemented yet: #{__FILE__}"
  end
end
