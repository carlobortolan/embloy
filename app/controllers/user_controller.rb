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
    @user = Current.user
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

end

