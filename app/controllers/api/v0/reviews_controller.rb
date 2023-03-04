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
            if Review.all.where(:created_by => decoded_token["sub"], :subject => params[:id]).present?
              render status: 422, json: { "review": [
                {
                  "error": "ERR_UNNECESSARY",
                  "description": "Attribute is already submitted."
                }
              ]
              }
            else
              user_id = User.find(params[:id]).id
              review = Review.new(review_params)
              review.subject = user_id
              review.created_by = decoded_token["sub"]
              review.save!
              render status: 200, json: { "message": "Review submitted!" }
            end
          rescue ActiveRecord::RecordNotFound
            if params[:id].nil?
              render status: 400, json: { "user": [
                {
                  "error": "ERR_BLANK",
                  "description": "Attribute can't be blank."
                }
              ]
              }
            else
              render status: 400, json: { "user": [
                {
                  "error": "ERR_INVALID",
                  "description": "Attribute is malformed or unknown."
                }
              ]
              }
            end


          end
        end
      end

      def review_params
        params.require(:review).permit(:rating, :message, :job_id)
      end
    end
  end
end