# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'CompanyController' do
  before(:all) do
    charset = ('a'..'z').to_a + ('A'..'Z').to_a

    ### COMPANY USER CREATION ###

    # Create valid verified company with own jobs
    @valid_company_has_own_jobs = User.create!(
      first_name: 'Max',
      last_name: 'Mustermann',
      email: "#{(0...16).map { charset.sample }.join}@embloy.com",
      password: 'password',
      password_confirmation: 'password',
      user_role: 'verified',
      activity_status: 1
    )
    @valid_company_has_own_jobs.set_payment_processor :fake_processor, allow_fake: true
    @valid_company_has_own_jobs.pay_customers
    @valid_company_has_own_jobs.payment_processor.customer
    @valid_company_has_own_jobs.payment_processor.charge(19_00)
    @valid_company_has_own_jobs.payment_processor.subscribe(plan: 'price_1OUuWFKMiBrigNb6lfAf7ptj')

    # Create valid verified company without jobs
    @valid_company = User.create!(
      first_name: 'Max',
      last_name: 'Mustermann',
      email: "#{(0...16).map { charset.sample }.join}@embloy.com",
      password: 'password',
      password_confirmation: 'password',
      user_role: 'verified',
      activity_status: 1
    )
    @valid_company.set_payment_processor :fake_processor, allow_fake: true
    @valid_company.pay_customers
    @valid_company.payment_processor.customer
    @valid_company.payment_processor.charge(19_00)
    @valid_company.payment_processor.subscribe(plan: 'price_1OUuWFKMiBrigNb6lfAf7ptj')

    @unsuscribed_company = User.create!(
      first_name: 'Max',
      last_name: 'Mustermann',
      email: "#{(0...16).map { charset.sample }.join}@embloy.com",
      password: 'password',
      password_confirmation: 'password',
      user_role: 'verified',
      activity_status: 1
    )

    # Create valid unverified user
    @unverified_company = User.create!(
      first_name: 'Max',
      last_name: 'Mustermann',
      email: "#{(0...16).map { charset.sample }.join}@embloy.com",
      password: 'password',
      password_confirmation: 'password',
      user_role: 'spectator',
      activity_status: 0
    )

    # Blacklisted verified user
    @blacklisted_company = User.create!(
      first_name: 'Max',
      last_name: 'Mustermann',
      email: "#{(0...16).map { charset.sample }.join}@embloy.com",
      password: 'password',
      password_confirmation: 'password',
      user_role: 'verified',
      activity_status: 1
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
  end

  describe '(GET: /api/v0/company/:id/board)' do
    context 'valid normal inputs' do
      it 'returns [200 Ok] and job JSONs if company has own jobs' do
        get("/api/v0/company/#{@valid_company_has_own_jobs.id.to_i}/board")
        expect(response).to have_http_status(200)
      end
      it 'returns [200 Ok] and job JSONs if company has no jobs' do
        get("/api/v0/company/#{@valid_company.id.to_i}/board")
        expect(response).to have_http_status(204)
      end
    end
    context 'invalid inputs' do
      it 'returns [403 Forbidden] for blacklisted company' do
        get("/api/v0/company/#{@blacklisted_company.id.to_i}/board")
        expect(response).to have_http_status(403)
      end
      it 'returns [403 Forbidden] for unverified company' do
        get("/api/v0/company/#{@unverified_company.id.to_i}/board")
        expect(response).to have_http_status(403)
      end
      it 'returns [403 Forbidden] for company without active subscription' do
        get("/api/v0/company/#{@unsuscribed_company.id.to_i}/board")
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
        get("/api/v0/company/#{@valid_company_has_own_jobs.id.to_i}/board/#{@listed_job.job_slug}")
        expect(response).to have_http_status(200)
      end
    end
    context 'invalid inputs' do
      it 'returns [403 Forbidden] for blacklisted company' do
        get("/api/v0/company/#{@blacklisted_company.id.to_i}/board/#{@listed_job.job_slug}")
        expect(response).to have_http_status(403)
      end
      it 'returns [403 Forbidden] for unverified company' do
        get("/api/v0/company/#{@unverified_company.id.to_i}/board/#{@listed_job.job_slug}")
        expect(response).to have_http_status(403)
      end
      it 'returns [403 Forbidden] for company without active subscription' do
        get("/api/v0/company/#{@unsuscribed_company.id.to_i}/board/#{@listed_job.job_slug}")
        expect(response).to have_http_status(403)
      end
      it 'returns [404 Not Found] for non existing job' do
        get("/api/v0/company/#{@valid_company_has_own_jobs.id.to_i}/board/non_existing_job_slug")
        expect(response).to have_http_status(404)
      end
      it 'returns [409 Conflict] for unlisted job' do
        get("/api/v0/company/#{@valid_company_has_own_jobs.id.to_i}/board/#{@unlisted_job.job_slug}")
        expect(response).to have_http_status(409)
      end
      it 'returns [409 Conflict] for archived job' do
        get("/api/v0/company/#{@valid_company_has_own_jobs.id.to_i}/board/#{@archived_job.job_slug}")
        expect(response).to have_http_status(409)
      end
      it 'returns [409 Conflict] for inactive job' do
        get("/api/v0/company/#{@valid_company_has_own_jobs.id.to_i}/board/#{@inactive_job.job_slug}")
        expect(response).to have_http_status(409)
      end
    end
  end
end
