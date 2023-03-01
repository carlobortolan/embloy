class ApplicationStatusNotification < Noticed::Base
  deliver_by :database
  deliver_by :email, mailer: "EmployeeApplicationMailer", if: :email_notifications?, unless: :read?, debug: true

  param :application, :job, :user

  def email_notifications?
    recipient.email_notifications?
  end

  def message
    @job = params[:job]
    @application = params[:application]
    @user = user
    "The status of your application for job #{@job.title} has changed."
  end

  def url
    job_path(params[:job])
  end
end
