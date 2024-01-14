# frozen_string_literal: true

# The Application class represents a job application in the application.
class Application < ApplicationRecord
  acts_as_paranoid
  after_create_commit :notify_recipient
  # after_update_commit :notify_applicant
  before_destroy :cleanup_notifications

  self.primary_keys = :user_id, :job_id

  has_noticed_notifications model_name: 'Notification'
  # has_rich_text :application_text
  # has_one_attached :cv

  belongs_to :job, counter_cache: true
  belongs_to :user, counter_cache: true
  has_one :application_attachment,
          dependent: :destroy
  accepts_nested_attributes_for :application_attachment
  delegate :cv, to: :application_attachment,
                allow_nil: true

  # validates :user_id, presence: { error: 'ERR_BLANK', description: "Attribute can't be blank" },
  #                   uniqueness: { scope: :job_id, error: 'ERR_TAKEN', description: 'You already submitted an application for this job' }
  validates :job_id, presence: { error: 'ERR_BLANK', description: "Attribute can't be blank" }
  validates :application_text, length: { minimum: 0, maximum: 1000, error: 'ERR_LENGTH', description: 'Attribute length is invalid' }, presence: true
  # validates :response, length: { minimum: 0, maximum: 500, error: 'ERR_LENGTH', description: 'Attribute length is invalid' }, presence: false
  validates :status, inclusion: { in: %w[-1 0 1], error: 'ERR_INVALID', description: 'Attribute is invalid' }, presence: false

  def notify_recipient
    return if job.user.eql? user

    ApplicationNotification.with(application: %i[user_id job_id], job:).deliver_later(job.user)
  end

  def notify_applicant(new_status, new_response)
    #    return unless job.user.eql? user
    ApplicationStatusNotification.with(application: %i[user_id job_id], user:, job:, status: new_status, response: new_response).deliver_later(user)
  end

  def accept(response)
    raise 'ERR_LENGTH: Attribute length is invalid' unless response.length.between?(0, 500)

    notify_applicant(1, response)
    Application.where(user_id:, job_id:).update_all(status: 1, response:)
  end

  def reject(response)
    raise 'ERR_LENGTH: Attribute length is invalid' unless response.length.between?(0, 500)

    notify_applicant(-1, response)
    Application.where(user_id:, job_id:).update_all(status: -1, response:)
  end

  private

  def cleanup_notifications
    notifications_as_application.destroy_all
  end
end
