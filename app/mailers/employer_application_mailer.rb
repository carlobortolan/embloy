# frozen_string_literal: true

# The EmployerApplicationMailer handles sending emails related to employer applications.
class EmployerApplicationMailer < ApplicationMailer
  def application_notification
    @job = params[:job]
    @application = params[:application]
    @applicant = User.find(params[:application][:user_id])
    @recipient = params[:recipient]
    mail from: ENV.fetch('EMAIL_NOREPLY_USER', nil),
         to: @recipient.email, subject: 'Embloy - New application'
  end

  def application_status_notification
    @user_email = params[:user_email]
    @application = params[:application]
    @job = params[:job]
    @status = params[:status]
    @response = params[:response]
    @user_first_name = params[:user_first_name]
    mail from: ENV.fetch('EMAIL_NOREPLY_USER', nil),
         to: @user_email, subject: 'Embloy - Application status changed'
  end
end
