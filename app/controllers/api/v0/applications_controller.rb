# frozen_string_literal: true

module Api
  module V0
    # ApplicationsController handles application-related actions
    class ApplicationsController < ApiController
      include ApplicationBuilder
      before_action :verify_path_job_id, except: %i[show_all create accept reject]
      before_action :verify_path_active_job_id, only: %i[accept reject]
      before_action :verify_path_listed_job_id, only: %i[create]
      before_action :must_be_verified!
      before_action :must_be_subscribed!, only: %i[accept reject]

      # Returns all applications for a given job
      def show
        must_be_owner!(application_show_params[:id], Current.user.id)
        applications = @job.applications.find_by_sql("SELECT * FROM applications a WHERE a.job_id = #{@job.job_id}")
        render_applications(applications || [])
      end

      # Returns all applications submitted to an employer
      def show_all
        jobs = Current.user.jobs
        applications = Application.where(job_id: jobs.pluck(:job_id))
        render_applications(applications || [])
      end

      # rubocop:disable Metrics/AbcSize
      # Returns a single application including details
      def show_single
        set_at_job(application_show_params[:id])
        must_be_owner!(application_show_params[:id], Current.user.id) if application_show_params[:application_id]
        application = @job.applications.includes(:application_attachment,
                                                 :application_answers).find_by_sql(['SELECT * FROM applications a WHERE a.job_id = ? AND a.user_id = ?', @job.job_id,
                                                                                    application_show_params[:application_id] || Current.user.id]).first

        application_attachment = ApplicationAttachment.find_by(job_id: @job.id, user_id: application_show_params[:application_id] || Current.user.id)

        render_application(application, application_attachment)
      end
      # rubocop:enable Metrics/AbcSize

      def create
        apply_for_job
      end

      def accept
        must_be_owner!(application_modify_params[:id], Current.user.id)
        set_at_job(application_modify_params[:id])
        application = @job.applications.where(user_id: application_modify_params[:application_id]).first
        handle_accept(application)
      rescue ActiveRecord::RecordNotFound
        render status: 404, json: { message: 'Not found.' }
      end

      def reject
        must_be_owner!(application_modify_params[:id], Current.user.id)
        set_at_job(application_modify_params[:id])
        application = @job.applications.where(user_id: application_modify_params[:application_id]).first
        handle_reject(application)
      rescue ActiveRecord::RecordNotFound
        render status: 404, json: { message: 'Not found.' }
      end

      private

      def render_applications(applications)
        if applications.empty?
          render status: 204, json: { applications: }
        else
          render status: 200, json: { applications: }
        end
      end

      def render_application(application, application_attachment = nil)
        if application.nil?
          render status: 204, json: { application: {} }
        else
          attachment_url = application_attachment ? rails_blob_url(application_attachment.cv) : nil
          render status: 200, json: {
            application:,
            application_attachment: { attachment: application_attachment, url: attachment_url },
            application_answers: application.application_answers.as_json(include: { attachment: { methods: :url } })
          }
        end
      end

      def handle_accept(application)
        if application.nil?
          render status: 404, json: { message: 'Not found.' }
        elsif application.accepted?
          render status: 400, json: { message: 'Already accepted.' }
        else
          begin
            application.accept(application_modify_params[:response] || 'ACCEPTED')
            render status: 200, json: { message: 'Application successfully accepted.' }
          rescue RuntimeError => e
            render status: 400, json: { message: e.message }
          end
        end
      end

      def handle_reject(application)
        if application.nil?
          render status: 404, json: { message: 'Not found.' }
        elsif application.rejected?
          render status: 400, json: { message: 'Already rejected.' }
        else
          begin
            application.reject(application_modify_params[:response] || 'REJECTED')
            render status: 200, json: { message: 'Application successfully rejected.' }
          rescue RuntimeError => e
            render status: 400, json: { message: e.message }
          end
        end
      end

      def application_params
        params.except(:format).permit(:id, :application_text, :application_attachment, application_answers: %i[application_option_id answer file])
      end

      def application_modify_params
        params.except(:format).permit(:application_id, :response, :id)
      end

      def application_show_params
        params.except(:format).permit(:application_id, :id)
      end
    end
  end
end
