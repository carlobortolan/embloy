class ApplicationStatusNotification < Noticed::Base
  deliver_by :database
  deliver_by :email, mailer: 'EmployerApplicationMailer', debug: false, method: :application_status_notification, if: :email_notifications?
  #  deliver_by :email, mailer: "EmployeeApplicationMailer", if: :email_notifications?, unless: :read?, debug: true

  param :application, :user, :job, :status, :response

  def email_notifications?
    recipient.application_notifications?
  end

  def message
    @job = params[:application].job
    @application = params[:application]
    @user = recipient
    "The status of your application for #{@job.title} has changed."
  end

  def url
    job_path(params[:job])
  end
end
