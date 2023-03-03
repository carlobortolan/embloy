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
        if require_user_logged_in!
          if @review.save
            redirect_to @review
          else
            render :new, status: :unprocessable_entity
          end

        end
      end

      def application_params
        params.require(:review).permit(:rating, :message, :application_documents)
      end
    end
  end
end