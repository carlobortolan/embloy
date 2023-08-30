# frozen_string_literal: true
module Api
  module V0
    class UserController < ApiController
      before_action :verify_access_token

      def own_jobs
        begin
          verified!(@decoded_token["typ"])
          # Cache attachment (should also be done with image_url)
          jobs = User.find(@decoded_token["sub"].to_i).jobs.includes([:rich_text_description]).order(created_at: :desc)

          # TODO: image_url currently not working with JSON.
          # This doesn't work:
          # jobs.empty? ? render(status: 204, json: { "jobs": jobs }) : render(status: 200, json: { "jobs": jobs })

          # This works, but sends job without image_url:
          jobs.empty? ? render(status: 204, json: { "jobs": jobs }) : render(status: 200, json: "jobs: #{jobs.to_json(except: [:image_url])}")
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
          preferences = Preferences.find_by_user_id(user.id)
          if preferences.nil?
            not_found_error('preferences')
          else
            preferences.blank? ? render(status: 204, json: { "preferences": preferences }) : render(status: 200, json: { "preferences": preferences })
          end
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
          render(status: 200, json: { "user": user })
        rescue ActiveRecord::RecordNotFound
          not_found_error('user')
        end
      end

      def edit
        # TODO
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

# frozen_string_literal: true
