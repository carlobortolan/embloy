# frozen_string_literal: true

module Api
  module V0
    # CompanyController handles job-related actions
    class CompanyController < ApiController
      skip_before_action :set_current_user, only: %i[feed]

      # Returns all public jobs (without attachments and options) of a company user
      def feed
        must_be_subscribed!(params[:id])
        jobs = Current.user.jobs.except(:includes)
                      .select(:job_id, :title, :job_type, :job_slug, :job_status, :referrer_url, :salary, :currency,
                              :start_slot, :duration, :code_lang, :longitude, :latitude,
                              :country_code, :postal_code, :city, :address, :view_count,
                              :applications_count, :created_at, :updated_at)
                      .where(job_status: :listed)
                      .order(created_at: :desc)
        render(status: jobs.nil? || jobs.empty? ? 204 : 200, json: { jobs:, company: Current.user })
      end
    end
  end
end
