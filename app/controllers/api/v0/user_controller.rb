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
          render(status: 200, json: "{\"jobs\": [#{Job.get_jsons_include_user(upcoming_jobs)}]}")
        end
      end

      def own_jobs
        jobs = Current.user.jobs.includes([:rich_text_description]).order(created_at: :desc)
        if jobs.empty?
          render(status: 204,
                 json: { jobs: })
        else
          render(status: 200,
                 json: "{\"jobs\": [#{Job.jsons_for(jobs)}]}")
        end
      end

      def own_applications
        applications = Application.where(user_id: Current.user.id)
                                  .includes(job: %i[rich_text_description
                                                    application_options
                                                    user]).includes([:application_answers])
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
          render(status: 200,
                 json: "{\"user\": #{User.json_for(Current.user)}}")
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
        render status: 200,
               json: { message: 'User deleted!' }
      end

      def upload_image
        attach_image if params[:image_url].present?
        render status: 200, json: { image_url: Current.user.image_url.url.to_s }
      rescue Excon::Error::Socket, ActiveStorage::IntegrityError => e
        Rails.logger.error("Failed to upload image: #{e.message}")
        render status: 500, json: { error: 'Failed to upload image:' }
      end

      def events
        pipeline = ApplicationEvent.all.where(user_id: Current.user.id).order('created_at DESC').group_by(&:job_id)

        pipeline.empty? ? render(status: 204, json: { pipeline: [] }) : render(status: 200, json: { pipeline: })
      end

      private

      def build_applications_json(applications)
        applications.includes(:application_answers, application_answers: :attachment_attachment).map do |application|
          {
            application:,
            job: Job.get_json_include_user_exclude_image(application.job),
            application_answers: application.application_answers.as_json(include: { attachment: { methods: :url } })
          }
        end
      end

      def fetch_upcoming_jobs
        applications = Application.all.where(user_id: Current.user.id, status: '1')
        return [] if applications.empty?

        applications.map { |i| Job.find(i.job_id) }
      end

      def attach_image
        image = params[:image_url]
        if image.is_a?(ActionDispatch::Http::UploadedFile)
          Current.user.image_url.attach(io: image.open, filename: image.original_filename, content_type: image.content_type)
        else
          default_image = Rails.root.join('app/assets/images/logo-light.svg')
          Current.user.image_url.attach(io: File.open(default_image), filename: 'default.svg', content_type: 'image/svg')
        end
      end

      def user_params
        params.require(:user).permit(:first_name, :last_name, :email, :phone, :degree, :date_of_birth, :country_code, :city,
                                     :postal_code, :address, :twitter_url, :facebook_url, :linkedin_url, :instagram_url, :github_url, :portfolio_url,
                                     :application_notifications, :communication_notifications, :marketing_notifications, :security_notifications)
      end
    end
  end
end
