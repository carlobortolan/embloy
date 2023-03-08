class UserController < ApplicationController
  before_action :require_user_logged_in

  def index
    @user = Current.user
    @user.update(view_count: @user.view_count + 1)
    # @jobs = @user.jobs.includes(:rich_text_body).order(created_at: :desc)
    @jobs = @user.jobs.order(created_at: :desc)
    @total_job_views = 0

    @jobs.each do |job|
      @total_job_views += job.view_count
    end
  end

  def settings
    @user = Current.user
  end

  def edit
    puts "STARTED EDIT"
    @user = Current.user
  end

  def update
    puts "STARTED UPDATE"
    @user = Current.user
    require_user_logged_in
    if @user.update(user_params)
      redirect_to @user
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def preferences
    @user = Current.user
  end

  def own_jobs
    # @jobs = @user.jobs.includes(:rich_text_body).order(created_at: :desc)
    @jobs = Current.user.jobs.order(created_at: :desc)
  end

  def own_applications
    @applications = Application.includes(:user).all.where("user_id = #{Current.user.id}").order("updated_at DESC")
  end

  private

  def user_params
    params.require(:user).permit(:first_name, :last_name, :email, :date_of_birth, :country_code, :city, :postal_code, :address)
    # TODO: expand
  end

  # PHONE
  # DEGREE

end

