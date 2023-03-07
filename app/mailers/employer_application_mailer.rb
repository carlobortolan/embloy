class EmployerApplicationMailer < ApplicationMailer
  def application_notification
    @job = params[:job]
    @application = params[:application]
    @applicant = User.find(params[:job].user_id)
    @recipient = params[:recipient]
    mail from: ENV['EMAIL_NOREPLY_USER'], to: @recipient.email, subject: "Embloy - New application"
  end

  def application_status_notification
    @user = params[:user]
    @application = params[:application]
    @job = params[:job]
    @status = params[:status]
    @response = params[:response]
    mail from: ENV['EMAIL_NOREPLY_USER'], to: @user.email, subject: 'Embloy - Application status changed'
  end

end
