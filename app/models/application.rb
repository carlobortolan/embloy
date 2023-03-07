class Application < ApplicationRecord
  after_create_commit :notify_recipient
  # after_update_commit :notify_applicant
  before_destroy :cleanup_notifications
  has_noticed_notifications model_name: 'Notification'

  # has_rich_text :application_text

  belongs_to :job, counter_cache: true
  belongs_to :user, counter_cache: true, :dependent => :destroy

  validates :user_id, presence: true
  validates :job_id, presence: true
  validates :application_text, presence: true, length: { minimum: 10 }
  validates :response, presence: false

  def notify_recipient
    return if job.user.eql? user
    ApplicationNotification.with(application: [:user_id, :job_id], job: job).deliver_later(job.user)
  end

  def notify_applicant(new_status, new_response)
    #    return unless job.user.eql? user
    ApplicationStatusNotification.with(application: [:user_id, :job_id], user: user, job: self.job, status: new_status, response: new_response).deliver_later(user)
  end

  def accept (response)
    notify_applicant(1, response)
    ActiveRecord::Base.connection.execute("UPDATE applications SET status = '1', response = '#{response}' WHERE user_id = #{user_id} AND job_id = #{job_id}")
  end

  def reject(response)
    notify_applicant(-1, response)
    ActiveRecord::Base.connection.execute("UPDATE applications SET status = '-1', response = '#{response}' WHERE user_id = #{user_id} AND job_id = #{job_id}")
  end

  private

  def cleanup_notifications
    notifications_as_application.destroy_all
  end
end
