# frozen_string_literal: true
module Api
  module V0
    class UserController < ApiController
      before_action :verify_access_token

      def own_jobs
        begin
          verified!(@decoded_token["typ"])
          jobs = User.find(id: @decoded_token["sub"].to_i).jobs.order(created_at: :desc)
          jobs.empty? ? render( status: 204, json: { "jobs": jobs }) : render(status: 200, json: { "jobs": jobs })
        end
      end

      def own_applications
        begin
          verified!(@decoded_token["typ"])
          applications = Application.all.where(user_id: @decoded_token["sub"].to_i)
          applications.empty? ? render(status: 204, json: { "applications": applications }) : render(status: 200, json: { "applications": applications })
        end
      end

      def own_reviews
        begin
          verified!(@decoded_token["typ"])
          reviews = Review.all.where(subject: @decoded_token["sub"].to_i)
          reviews.empty? ? render(status: 204, json: { "reviews": reviews }) : render(status: 200, json: { "reviews": reviews })
        end
      end
    end
  end
end

# frozen_string_literal: true
