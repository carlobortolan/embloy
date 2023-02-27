class Application < ApplicationRecord
  after_create_commit :notify_recipient
  before_destroy :cleanup_notifications
  has_noticed_notifications model_name: 'Notification'
  # has_rich_text :application_text

  belongs_to :job
  belongs_to :user, :dependent => :destroy

  # validates :applicant_id, presence: true
  validates :user_id, presence: true
  validates :job_id, presence: true
  validates :application_text, presence: true, length: { minimum: 10 }

  def get_name
    UserService.new.get_user_name(user_id.to_i)
  end

  def notify_recipient
    puts "T-4"
    ApplicationNotification.with(application: [:user_id, :job_id], job: job).deliver_later(job.user)
    puts "T-5"
  end

  private

  def cleanup_notifications
    notifications_as_application.destroy_all
  end
end
