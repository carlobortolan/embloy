# frozen_string_literal: true

# The UserController is responsible for handling user-related actions.
module Api
  module V0
    # UserController handles user-related actions
    class UserController < ApiController
      def upcoming
        upcoming_jobs = fetch_upcoming_jobs

        if upcoming_jobs.empty?
          render(status: 204, json: { jobs: upcoming_jobs })
        else
          render(status: 200, json: { jobs: upcoming_jobs.map { |job| job.dao(include_employer: true)[:job] } })
        end
      end

      def own_jobs
        jobs = Current.user.jobs.order(created_at: :desc)
        if jobs.empty?
          render(status: 204, json: { jobs: })
        else
          render(status: 200, json: { jobs: jobs.map { |job| job.dao[:job] } })
        end
      end

      def own_applications
        applications = Application.includes(application_answers: { attachment_attachment: :blob }, application_events: [], job: [:rich_text_description,
                                                                                                                                 :application_options,
                                                                                                                                 { user: :image_url_attachment }]).where(user_id: Current.user.id)
        return render(status: 204, json: { applications: {} }) if applications.empty?

        render status: 200, json: build_applications_json(applications)
      end

      def own_reviews
        reviews = Review.all.where(subject: Current.user.id)
        if reviews.empty?
          render(status: 204,
                 json: { reviews: })
        else
          render(status: 200,
                 json: { reviews: })
        end
      end

      def preferences
        if Current.user.preferences.nil?
          Current.user.create_preferences
          render :preferences, status: :unprocessable_entity unless Current.user.save
        end
        render(status: 200, json: { preferences: Current.user.preferences })
      end

      def update_preferences
        # TODO
      end

      def remove_image
        Current.user.image_url.purge if Current.user.image_url.attached?
        render status: 200,
               json: { message: 'Profile image successfully removed.' }
      end

      def show
        if Current.user.nil?
          render(status: 204)
        else
          render(status: 200, json: Current.user.dao(include_user: true))
        end
      end

      def edit
        if Current.user.nil?
          render(status: 204)
        elsif Current.user.update(user_params)
          render(status: 200,
                 json: { message: 'Successfully updated user.' })
        else
          render(status: 422,
                 json: { message: 'Failed to update user.',
                         errors: Current.user.errors.full_messages })
        end
      end

      def destroy
        Current.user.destroy!
        render status: 200, json: { message: 'User deleted!' }
      end

      def upload_image
        render status: 400, json: { error: 'No image provided' } unless params[:image_url]&.present?

        if Current.user.update(image_url: params[:image_url])
          render status: 200, json: { image_url: Current.user.image_url.url.to_s }
        else
          render status: 400, json: { error: 'Bad request', details: Current.user.errors.details }
        end
      rescue StandardError => e
        Rails.logger.error("Failed to upload image: #{e.message}")
        render status: 500, json: { error: 'Failed to upload image' }
      end

      def events
        pipeline = ApplicationEvent.all.where(user_id: Current.user.id).order('created_at DESC').group_by(&:job_id)

        pipeline.empty? ? render(status: 204, json: { pipeline: [] }) : render(status: 200, json: { pipeline: })
      end

      def deactivate_integration
        Integrations::IntegrationsController.deactivate(Current.user, deactivate_integration_params[:source], deactivate_integration_params[:archive_jobs] == '1')
        render status: 200, json: { message: 'Integration deactivated successfully.' }
      end

      private

      def build_applications_json(applications)
        applications.map do |application|
          {
            application:,
            job: application.job.dao(include_employer: true)[:job],
            application_answers: application.application_answers.as_json(include: { attachment: { methods: :url } }),
            application_events: application.application_events
          }
        end
      end

      def fetch_upcoming_jobs
        applications = Application.all.includes(:job).where(user_id: Current.user.id, status: '1')
        return [] if applications.empty?

        applications.map(&:job)
      end

      def user_params
        params.require(:user).permit(:first_name, :last_name, :email, :phone, :degree, :date_of_birth, :country_code, :city,
                                     :postal_code, :address, :twitter_url, :facebook_url, :linkedin_url, :instagram_url, :github_url, :portfolio_url,
                                     :application_notifications, :communication_notifications, :marketing_notifications, :security_notifications)
      end

      def deactivate_integration_params
        params.permit(:source, :archive_jobs)
      end
    end
  end
end
