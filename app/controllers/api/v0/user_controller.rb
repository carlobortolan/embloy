# frozen_string_literal: true
module Api
  module V0
    class UserController < ApiController
      def upcoming
          verified!(@decoded_token["typ"])
          applications = Application.all.where(user_id: Current.user.id, status: "1")

          if !applications.empty?
            upcoming_jobs = []
            applications.each do |i|
              upcoming_jobs << Job.find(i.job_id)
            end
            upcoming_jobs.empty? ? render(status: 204, json: { "jobs": upcoming_jobs }) : render(status: 200, json: "{\"jobs\": [#{Job.get_jsons_include_user(upcoming_jobs)}]}")
          else
            render(status: 204, json: { "jobs": "" })
          end
      end

      def own_jobs
          verified!(@decoded_token["typ"])
          jobs = Current.user.jobs.includes([:rich_text_description]).order(created_at: :desc)
          jobs.empty? ? render(status: 204, json: { "jobs": jobs }) : render(status: 200, json: "{\"jobs\": [#{Job.get_jsons(jobs)}]}")
      end

      def own_applications
          verified!(@decoded_token["typ"])
          applications = Application.all.where(user_id: Current.user.id)
          applications.empty? ? render(status: 204, json: { "applications": applications }) : render(status: 200, json: { "applications": applications })
      end

      def own_reviews
          verified!(@decoded_token["typ"])
          reviews = Review.all.where(subject: Current.user.id)
          reviews.empty? ? render(status: 204, json: { "reviews": reviews }) : render(status: 200, json: { "reviews": reviews })
      end

      def get_preferences
          verified!(@decoded_token["typ"])
          
          if Current.user.preferences.nil?
            Current.user.create_preferences
            unless Current.user.save
              flash[:alert] = 'Preferences could not be saved'
              render :preferences, status: :unprocessable_entity
            end
          end
          render(status: 200, json: { "preferences": Current.user.preferences })
      end

      def update_preferences
        # TODO
      end

      def remove_image
        verified!(@decoded_token["typ"])
        
        Current.user.image_url.purge if Current.user.image_url.attached?
        render status: 200, json: { "message": "Profile image successfully removed." }
      end

      def show
          verified!(@decoded_token["typ"])
          
          if Current.user.nil?
            render(status: 204)
          else
            puts "Json = #{User.get_json(Current.user)}"
            render(status: 200, json: "{\"user\": #{User.get_json(Current.user)}}")
          end
      end

      def edit
          verified!(@decoded_token["typ"])
          
          if Current.user.nil?
            render(status: 204)
          else
            if Current.user.update(user_params)
              render(status: 200, json: { "message": "Successfully updated user." })
            else
              render(status: 422, json: { "message": "Failed to update user.", "errors": Current.user.errors.full_messages })
            end
          end
      end

      def destroy
          verified!(@decoded_token["typ"])
          
          Current.user.destroy!
          render status: 200, json: { "message": "User deleted!" }
      end

      def upload_image
        puts "PARAMS = #{params}"
          verified!(@decoded_token["typ"])
          
          Current.user.image_url.attach(params[:image_url]) if params[:image_url].present?
          render status: 200, json: { "image_url": "#{Current.user.image_url.url}" }
      end
    end
  end
end

def user_params
  params.require(:user).permit(:first_name, :last_name, :email, :phone, :degree, :date_of_birth, :country_code, :city, :postal_code, :address, :twitter_url, :facebook_url, :linkedin_url, :instagram_url)
end
