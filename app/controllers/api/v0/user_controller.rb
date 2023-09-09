# frozen_string_literal: true
module Api
  module V0
    class UserController < ApiController
      before_action :verify_access_token

      def upcoming
        begin
          verified!(@decoded_token["typ"])

          user = User.find(@decoded_token["sub"].to_i)
          applications = Application.all.where(user_id: user.id, status: "1")

          if !applications.empty?
            upcoming_jobs = []
            applications.each do |i|
              upcoming_jobs << Job.find(i.job_id)
            end
            upcoming_jobs.empty? ? render(status: 204, json: { "jobs": upcoming_jobs }) : render(status: 200, json: "{\"jobs\": [#{Job.get_jsons(upcoming_jobs)}]}")
          else
            render(status: 204, json: { "jobs": "" })
          end
        rescue ActiveRecord::RecordNotFound
          not_found_error('user')
        end
      end

      def own_jobs
        begin
          verified!(@decoded_token["typ"])
          jobs = User.find(@decoded_token["sub"].to_i).jobs.includes([:rich_text_description]).order(created_at: :desc)

          jobs.empty? ? render(status: 204, json: { "jobs": jobs }) : render(status: 200, json: "{\"jobs\": [#{Job.get_jsons(jobs)}]}")
        rescue ActiveRecord::RecordNotFound
          not_found_error('user')
        end
      end

      def own_applications
        begin
          verified!(@decoded_token["typ"])
          user = User.find(@decoded_token["sub"].to_i)
          applications = Application.all.where(user_id: user.id)
          applications.empty? ? render(status: 204, json: { "applications": applications }) : render(status: 200, json: { "applications": applications })
        rescue ActiveRecord::RecordNotFound
          not_found_error('user')
        end
      end

      def own_reviews
        begin
          verified!(@decoded_token["typ"])
          user = User.find(@decoded_token["sub"].to_i)
          reviews = Review.all.where(subject: user.id)
          reviews.empty? ? render(status: 204, json: { "reviews": reviews }) : render(status: 200, json: { "reviews": reviews })
        rescue ActiveRecord::RecordNotFound
          not_found_error('user')
        end
      end

      def get_preferences
        begin
          verified!(@decoded_token["typ"])
          user = User.find(@decoded_token["sub"].to_i)
          if user.preferences.nil?
            user.create_preferences
            unless user.save
              flash[:alert] = 'Preferences could not be saved'
              render :preferences, status: :unprocessable_entity
            end
          end
          render(status: 200, json: { "preferences": user.preferences })
        rescue ActiveRecord::RecordNotFound
          not_found_error('user')
        end
      end

      def update_preferences
        # TODO
      end

      def remove_image
        begin
          verified!(@decoded_token["typ"])
          user = User.find(@decoded_token["sub"].to_i)
          user.image_url.purge if user.image_url.attached?
          render status: 200, json: { "message": "Profile image successfully removed." }
        rescue ActiveRecord::RecordNotFound
          not_found_error('user')
        end
      end

      def show
        begin
          verified!(@decoded_token["typ"])
          user = User.find(@decoded_token["sub"].to_i)
          if user.nil?
            render(status: 204)
          else
            puts "Json = #{User.get_json(user)}"
            render(status: 200, json: "{\"user\": #{User.get_json(user)}}")
          end
        rescue ActiveRecord::RecordNotFound
          not_found_error('user')
        end
      end

      def edit
        begin
          verified!(@decoded_token["typ"])
          user = User.find(@decoded_token["sub"].to_i)
          if user.nil?
            render(status: 204)
          else
            if user.update(user_params)
              render(status: 200, json: { "message": "Successfully updated user." })
            else
              render(status: 422, json: { "message": "Failed to update user.", "errors": user.errors.full_messages })
            end
          end
        rescue ActiveRecord::RecordNotFound
          not_found_error('user')
        end
      end

      def destroy
        begin
          verified!(@decoded_token["typ"])
          user = User.find(@decoded_token["sub"].to_i)
          user.destroy!
          render status: 200, json: { "message": "User deleted!" }
        rescue ActiveRecord::RecordNotFound
          not_found_error('user')
        end

      end
    end
  end
end

def user_params
  params.require(:user).permit(:first_name, :last_name, :email, :phone, :degree, :date_of_birth, :country_code, :city, :postal_code, :address, :twitter_url, :facebook_url, :linkedin_url, :instagram_url)
end
