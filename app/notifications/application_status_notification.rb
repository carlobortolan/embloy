class ApplicationStatusNotification < Noticed::Base
  deliver_by :database
  deliver_by :email, mailer: 'EmployerApplicationMailer', debug: false, method: :application_status_notification, if: :email_notifications?
  #  deliver_by :email, mailer: "EmployeeApplicationMailer", if: :email_notifications?, unless: :read?, debug: true

  param :application, :user, :job, :status, :response

  def email_notifications?
    recipient.application_notifications?
  end

  def message
    # TODO: @carlobortolan FIX BUG
    "Update on #{params[:job]}"
  end

  def url
    # TODO: @carlobortolan FIX BUG
    # job_path(id)
  end
end
