# frozen_string_literal: true

module Api
  module V0
    # CompanyController handles job-related actions
    class CompanyController < ApiController
      skip_before_action :set_current_user, only: %i[board job]
      before_action :verify_path_company_id, except: %i[create]

      def show
        if show_params[:include_user] == '1' && @company == Current.user
          render(status: 200, json: Current.user.dao(include_user: true))
        else
          render(status: 200, json: @company.dao)
        end
      end

      def create
        must_be_subscribed!
        return conflict_error('company', 'You already have a company account') if Current.user.company?

        company, errors = Current.user.switch_to_company(company_params)

        if errors
          render status: 400, json: { error: 'Bad request', details: errors }
        else
          render(status: 201, json: company.dao)
        end
      end

      def update
        return access_denied_error('company') unless @company == Current.user

        err = CompanyUser.check_attributes(company_params, check_missing: false)
        return render(status: 400, json: { error: 'Bad request', details: err }) if err

        if @company.update(company_params)
          render(status: 200, json: @company.dao)
        else
          render status: 400, json: { error: 'Bad request', details: @company.errors.details }
        end
      end

      def destroy
        return access_denied_error('company') unless @company == Current.user

        @company.switch_to_private!
        render status: 200, json: { message: 'Company account deleted!' }
      end

      # Returns all public jobs (without attachments and options) of a company user
      def board
        jobs = @company.jobs.except(:includes)
                       .select(:job_id, :title, :job_type, :job_slug, :job_status, :referrer_url, :salary, :currency,
                               :start_slot, :duration, :code_lang, :longitude, :latitude,
                               :country_code, :postal_code, :city, :address, :view_count,
                               :applications_count, :created_at, :updated_at)
                       .where(job_status: :listed, activity_status: 1)
                       .order(created_at: :desc)
        render(status: jobs.nil? || jobs.empty? ? 204 : 200, json: @company.dao.merge(jobs: jobs.map { |job| job.dao[:job] }))
      end

      # Returns a single **listed** job (without options) of a company user
      def job
        job = @company.jobs.find_by(job_slug: params[:job_slug])

        return not_found_error('job') if job.nil?
        return conflict_error('job', 'Job is not listed or active') unless job.job_status == 'listed' && job.activity_status == 1

        render(status: 200, json: @company.dao.merge(job.dao(include_image: true, include_description: true)))
      end

      private

      def company_params
        params.permit(:company_name, :company_slug, :company_phone, :company_email, :company_industry, :company_description, :company_logo, company_urls: [])
      end

      def show_params
        params.permit(:include_user)
      end
    end
  end
end
