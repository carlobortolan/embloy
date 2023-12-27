# frozen_string_literal: true

# The EmployerApplicationMailer handles sending emails related to employer applications.
class EmployerApplicationMailer < ApplicationMailer
  def application_notification
    @job = params[:job]
    @application = params[:application]
    @applicant = User.find(params[:job].user_id)
    @recipient = params[:recipient]
    mail from: ENV.fetch('EMAIL_NOREPLY_USER', nil),
         to: @recipient.email, subject: 'Embloy - New application'
  end

  def application_status_notification
    @user = params[:user]
    @application = params[:application]
    @job = params[:job]
    @status = params[:status]
    @response = params[:response]
    mail from: ENV.fetch('EMAIL_NOREPLY_USER', nil),
         to: @user.email, subject: 'Embloy - Application status changed'
  end
end
