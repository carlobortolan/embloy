# frozen_string_literal: true

# The ApplicationStatusNotification class is responsible for handling notifications related to application status changes.
class ApplicationStatusNotification < Noticed::Base
  deliver_by :database
  deliver_by :email, mailer: 'EmployerApplicationMailer', debug: false, method: :application_status_notification,
                     if: :email_notifications?
  #  deliver_by :email, mailer: "EmployeeApplicationMailer", if: :email_notifications?, unless: :read?, debug: true

  param :application, :user, :job, :status,
        :response

  def email_notifications?
    recipient.application_notifications?
  end

  def message
    "Update on #{params[:job][:title]}"
  end

  def url
    return unless params[:job].present? && params[:id].present?

    "#{job_path(params[:job][:id])}#applicationForm"
  end
end
