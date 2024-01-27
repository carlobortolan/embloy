# frozen_string_literal: true

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
          #          render(status: 200,
          #                 json: "{\"jobs\": [#{Job.jsons_for(jobs)}]}")
        end
      end

      def own_applications
        applications = Application.where(user_id: Current.user.id)
        return render(status: 204, json: { applications: {} }) if applications.empty?

        applications_json = applications.map do |application|
          application_attachment = ApplicationAttachment.find_by(job_id: application.job_id, user_id: Current.user.id)
          attachment_url = application_attachment ? rails_blob_url(application_attachment.cv) : nil
          {
            application:,
            application_attachment: {
              attachment: application_attachment,
              url: attachment_url
            }
          }
        end

        render status: 200, json: applications_json
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
          unless Current.user.save
            flash[:alert] = 'Preferences could not be saved'
            render :preferences, status: :unprocessable_entity
          end
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
      end

      private

      def fetch_upcoming_jobs
        applications = Application.all.where(user_id: Current.user.id, status: '1')
        return [] if applications.empty?

        applications.map { |i| Job.find(i.job_id) }
      end

      def attach_image
        Current.user.image_url.attach(params[:image_url])
      rescue ActiveStorage::IntegrityError
        default_image = Rails.root.join('app/assets/images/logo-light.png')
        Current.user.image_url.attach(io: File.open(default_image), filename: 'default.png', content_type: 'image/png')
      end
    end
  end
end

def user_params
  params.require(:user).permit(:first_name, :last_name, :email, :phone, :degree, :date_of_birth, :country_code, :city,
                               :postal_code, :address, :twitter_url, :facebook_url, :linkedin_url, :instagram_url)
end
