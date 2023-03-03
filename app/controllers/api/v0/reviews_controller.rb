module Api
  module V0

    class ReviewsController < ApiController

=begin
      def index
        if require_user_be_owner!
          @reviews = @user.reviews.all
        end
      end
=end

      def create

        if request.headers["HTTP_ACCESS_TOKEN"].nil?
          render status: 400, json: { "access_token": [
            {
              "error": "ERR_BLANK",
              "description": "Attribute can't be blank"
            }
          ]
          }
        else
          begin
            decoded_token = AuthenticationTokenService::Access::Decoder.call(request.headers["HTTP_ACCESS_TOKEN"])[0]
            verified!(decoded_token["typ"])
          end
        end
        if require_user_logged_in!
          if @review.save
            redirect_to @review
          else
            render :new, status: :unprocessable_entity
          end

        end
      end

      def review_params
        params.require(:review).permit(:user_id, :rating, :message, :job_id)
      end
    end
  end
end