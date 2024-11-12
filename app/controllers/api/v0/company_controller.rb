# frozen_string_literal: true

module Api
  module V0
    # CompanyController handles job-related actions
    class CompanyController < ApiController
      skip_before_action :set_current_user, only: %i[board job]

      # Returns all public jobs (without attachments and options) of a company user
      def board
        must_be_subscribed!(params[:id])
        jobs = Current.user.jobs.except(:includes)
                      .select(:job_id, :title, :job_type, :job_slug, :job_status, :referrer_url, :salary, :currency,
                              :start_slot, :duration, :code_lang, :longitude, :latitude,
                              :country_code, :postal_code, :city, :address, :view_count,
                              :applications_count, :created_at, :updated_at)
                      .where(job_status: :listed, activity_status: 1)
                      .order(created_at: :desc)

        user_attributes = Current.user.slice(:id, :first_name, :last_name, :email, :phone, :linkedin_url, :instagram_url, :twitter_url, :facebook_url, :github_url, :portfolio_url,
                                             :user_role, :user_type)
        user_attributes[:image_url] = Current.user.image_url.attached? ? url_for(Current.user.image_url) : nil

        render(status: jobs.nil? || jobs.empty? ? 204 : 200, json: { company: user_attributes, jobs: })
      end

      # Returns a single **listed** job (without options) of a company user
      def job
        must_be_subscribed!(params[:id])
        job = Current.user.jobs.find_by(job_slug: params[:job_slug])

        return not_found_error('job') if job.nil?
        return removed_error('job') unless job.job_status == 'listed' && job.activity_status == 1

        job_attributes = job.slice(:job_id, :title, :job_type, :job_slug, :job_status, :referrer_url, :salary, :currency,
                                   :start_slot, :duration, :code_lang, :longitude, :latitude,
                                   :country_code, :postal_code, :city, :address, :view_count,
                                   :applications_count, :description, :created_at, :updated_at)
        job_attributes[:image_url] = job.image_url.attached? ? url_for(@job.image_url) : nil

        user_attributes = Current.user.slice(:id, :first_name, :last_name, :email, :phone, :linkedin_url, :instagram_url, :twitter_url, :facebook_url, :github_url, :portfolio_url,
                                             :user_role, :user_type)
        render(status: 200, json: { company: user_attributes, job: job_attributes })
      end
    end
  end
end
