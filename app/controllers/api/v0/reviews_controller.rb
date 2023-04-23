module Api
  module V0

    class ReviewsController < ApiController
      before_action :verify_access_token
      before_action :verify_path_job_id, only: [:create]



      def create
        must_be_verified!(@decoded_token["sub"])
      end











      def reate
          verified!(@decoded_token["typ"])
          if Review.all.where(:created_by => @decoded_token["sub"], :subject => params[:id], :job_id =>  params[:job_id]).present?
            unnecessary_error('review')
          else
            @decoded_token["sub"].to_i == params[:id].to_i ? raise(CustomExceptions::InvalidUser::Unknown) : false
            review_params["job_id"].present? ? must_be_owner!(review_params["job_id"], @decoded_token["sub"]) : false
            review = Review.new(review_params)
            review.subject = params[:id]
            review.created_by = @decoded_token["sub"]
            review.save!
            render status: 200, json: { "message": "Review submitted!" }
          end

      end

      def update
        begin

          verified!(@decoded_token["typ"])
          review = Review.find(params[:id])
          # TODO: Replace with general must_be_owner! method (if it then exist)
          ###############################################################################################################################################
          review.created_by.to_i == User.find(@decoded_token["sub"].to_i).id ? true : raise(CustomExceptions::Unauthorized::NotOwner) #
          ###############################################################################################################################################

          review.assign_attributes(review_params)
          review.save!
          render status: 200, json: { "message": "Review updated!" }
        rescue ActionController::ParameterMissing
          blank_error('review')

        rescue ActiveRecord::RecordNotFound
          if params[:id].nil?
            blank_error('review')
          else
            malformed_error('review')
          end
        rescue ActiveRecord::StatementInvalid
          malformed_error('review')

        end

      end

      def destroy

          begin
            verified!(@decoded_token["typ"])
            review = Review.find(params[:id])

            # TODO: Replace with general must_be_owner! method (if it then exist)
            ###############################################################################################################################
            review.created_by.to_i == User.find(@decoded_token["sub"].to_i).id ? true : raise(CustomExceptions::Unauthorized::NotOwner) #
            ###############################################################################################################################

            review.destroy!
            render status: 200, json: { "message": "Review deleted!" }

          rescue ActionController::ParameterMissing
            blank_error('review')
          rescue ActiveRecord::RecordNotFound
            if params[:id].nil?
              blank_error('review')
            else
              malformed_error('review')
            end
          rescue ActiveRecord::StatementInvalid
            malformed_error('review')

        end
      end

      def review_params
        params.require(:review).permit(:rating, :message, :job_id)
      end

    end
  end
end