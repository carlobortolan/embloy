class ApplicationsController < ApplicationController
  before_action :require_user_logged_in!
  attr_accessor(:application_service, :user_service)
  layout 'application'

  def initialize
    super
    @application_service = ApplicationService.new(nil, nil)
    @user_service = UserService.new
  end

  def index
    @job = Job.find(params[:job_id])
    require_user_be_owner!
    @applications = @job.applications.all
  end

  def show
    require_user_be_owner!
    @job = Job.find(params[:job_id])
    @application = @job.applications.find_by_sql("SELECT * FROM applications a WHERE a.applicant_id = #{params[:id]} and a.job_id = #{params[:job_id]}")
  end

  def new
    require_user_logged_in!
    @job = Job.find(params[:job_id])
    @application = Application.new
  end

  def create
    if require_user_logged_in!
      @job = Job.find(params[:job_id])
      begin
        @application_service.add_application(params[:job_id].to_i, Current.user.id.to_i, application_params[:application_text], application_params[:application_documents])
        redirect_to job_path(@job)
      rescue
        @applications = @job.applications.all
        redirect_to job_path(@job)
      end
    end
  end

  def destroy
    @job = Job.find(params[:job_id])
    if require_user_be_owner!
      redirect_to job_path(@job), alert: 'You are not the owner of this job!' if Current.user.id != @job.user_id
      @application = @job.applications.find(params[:applicant_id])
      @application.destroy
      redirect_to job_path(@job), status: :see_other
    end
  end

  def accept
    @job = Job.find(params[:job_id])
    if require_user_be_owner!
      @application_service.accept(params[:job_id].to_i, params[:application_id].to_i, "ACCEPTED")
      redirect_to job_path(@job), status: :see_other
    end
  end

  def reject
    @job = Job.find(params[:job_id])
    if require_user_be_owner!
      @application_service.reject(params[:job_id].to_i, params[:application_id].to_i, "REJECTED")
      redirect_to job_applications_path(params[:job_id])
    end
  end

  def reject_all
    @job = Job.find(params[:job_id])
    if require_user_be_owner!
      @application_service.reject_all(params[:job_id].to_i, "REJECTED")
      redirect_to job_path(@job), status: :see_other
    end
  end


  private

  def application_params
    params.require(:application).permit(:applicant_id, :application_text, :application_documents)
  end
end
