class PreferencesController < ApplicationController
  before_action :require_user_logged_in

  def update
    puts "STARTED UPDATE PREFERENCES CONTROLLER #{params}"
    @user = Current.user
    @preferences = Current.user.preferences
    # job_types = { "1": params[:job_type_1], "2": params[:job_type_2], "3": params[:job_type_3] }
    job_types = { "1": 10, "2": 7, "3": 5 }
    if @preferences.update(spontaneity: params[:spontaneity]) && @preferences.update(job_type: job_types)
      redirect_to @user, notice: "Updated preferences"
    else
      render :index, status: :unprocessable_entity, alert: "Could not save preferences"
    end
  end

  private

  def user_params
    params.require(:preferences).permit(:job_type_1, :job_type_2, :job_type_3, :spontaneity, :txtEmpPhone)
  end

end
