# frozen_string_literal: true

module Api
  module V0
    # ApplicationsController handles application-related actions
    class ApplicationsController < ApiController
      before_action :verify_path_job_id, :must_be_verified!

      def show
        must_be_owner!(params[:id], Current.user.id)
        applications = fetch_applications
        render_applications(applications)
      end

      def show_single
        set_at_job(params[:id])
        application = fetch_single_application
        render_application(application)
      end

      def create
        job = Job.find(params[:id])
        if job.cv_required
          create_application_with_cv(job)
        else
          create_application_without_cv(job)
        end
      rescue ActiveRecord::RecordNotUnique
        unnecessary_error('application')
      rescue ActiveRecord::RecordNotFound
        raise CustomExceptions::InvalidJob::Unknown
      end

      def accept
        must_be_owner!(params[:id], Current.user.id)
        job = Job.find(params[:id])
        application = job.applications.where(user_id: params[:application_id]).first
        handle_accept(application)
      rescue ActiveRecord::RecordNotFound
        render status: 404, json: { message: 'Not found.' }
      end

      def reject
        must_be_owner!(params[:id], Current.user.id)
        job = Job.find(params[:id])
        application = job.applications.where(user_id: params[:application_id]).first
        handle_reject(application)
      rescue ActiveRecord::RecordNotFound
        render status: 404, json: { message: 'Not found.' }
      end

      def create_application_with_cv(job)
        if params[:application_attachment].present?
          create_application_attachment(job)
        else
          malformed_error('application attachment')
        end
      end

      private

      def create_application_attachment(job)
        application_attachment = ApplicationAttachment.create!(
          user_id: Current.user.id,
          job_id: params[:id].to_i
        )

        attach_cv_to_application(application_attachment)
        save_application_attachment(application_attachment, job)
      end

      def attach_cv_to_application(application_attachment)
        application_attachment.cv.attach(params[:application_attachment])
      end

      def save_application_attachment(application_attachment, job)
        application_attachment.save!

        application = Application.create!(
          user_id: Current.user.id,
          job_id: job.job_id,
          application_text: params[:application_text],
          application_documents: 'empty',
          created_at: Time.now,
          updated_at: Time.now,
          response: 'No response yet ...'
        )

        application.user = Current.user
        application.job = job
        render status: 200, json: { message: 'Application submitted!' }
      end

      def fetch_applications
        @job.applications.find_by_sql("SELECT * FROM applications a WHERE a.job_id = #{@job.job_id}")
      end

      def render_applications(applications)
        if applications.empty?
          render status: 204, json: { applications: }
        else
          render status: 200, json: { applications: }
        end
      end

      def fetch_single_application
        @job.applications.find_by_sql("SELECT * FROM applications a WHERE a.job_id = #{@job.job_id} AND a.user_id = #{Current.user.id}")
      end

      def render_application(application)
        if application.empty? || application.nil?
          render status: 204, json: { application: }
        else
          render status: 200, json: { application: }
        end
      end

      def create_application_without_cv(job)
        application = Application.create!(
          user_id: Current.user.id,
          job_id: job.job_id,
          application_text: params[:application_text],
          created_at: Time.now,
          updated_at: Time.now,
          response: 'null'
        )

        application.user = Current.user

        if application.save!
          render status: 200, json: { message: 'Application submitted!' }
        else
          malformed_error('application')
        end
      end

      def handle_accept(application)
        if application.nil?
          render status: 404, json: { message: 'Not found.' }
        elsif application.status != '1'
          application.accept(application_params[:response] || 'ACCEPTED')
          render status: 200, json: { message: 'Application successfully accepted.' }
        else
          render status: 400, json: { message: 'Already accepted.' }
        end
      end

      def handle_reject(application)
        if application.nil?
          render status: 404, json: { message: 'Not found.' }
        elsif application.status != '-1'
          application.reject(application_params[:response] || 'REJECTED')
          render status: 200, json: { message: 'Application successfully rejected.' }
        else
          render status: 400, json: { message: 'Already rejected.' }
        end
      end

      def application_params
        params.permit(:application).permit(:user_id, :application_text, :application_documents, :response, :cv)
      end

      def application_params2
        params.permit(:user_id, :application_text, :application_documents, :response, :cv)
      end
    end
  end
end
