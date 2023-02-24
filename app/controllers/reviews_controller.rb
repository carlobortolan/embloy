class ReviewsController < ApplicationController
  def index
    if require_user_logged_in!
      puts "INDEXING"
      @user = Current.user
      @reviews = @user.reviews
    end
  end

  def for_user
    if require_user_logged_in!
      @user = User.find(params[:user_id])
      @reviews = @user.reviews
    end
  end

  def review_params
    params.require(:review).permit(:rating, :message, :created_by, :id)
  end
end

