# frozen_string_literal: true

# The Application class represents a job application in the application.
class Application < ApplicationRecord
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

  validates :user_id, presence: { "error": 'ERR_BLANK', "description": "Attribute can't be blank" },
                      uniqueness: { scope: :job_id, "error": 'ERR_TAKEN', "description": 'You already submitted an application for this job' }
  validates :job_id,
            presence: { "error": 'ERR_BLANK',
                        "description": "Attribute can't be blank" }
  validates :application_text,
            length: { minimum: 0, maximum: 1000, "error": 'ERR_LENGTH', "description": 'Attribute length is invalid' }, presence: true
  validates :response,
            length: { minimum: 0, maximum: 500, "error": 'ERR_LENGTH', "description": 'Attribute length is invalid' }, presence: false
  validates :status, inclusion: { in: %w[-1 0 1], "error": 'ERR_INVALID', "description": 'Attribute is invalid' },
                     presence: false

  def create_from(user_id, job_id, params)
    job = Job.find(job_id)
    application_attachment = create_application_attachment(user_id, job_id, params)
    create_application(user_id, job, params, application_attachment)
  rescue ActiveRecord::RecordInvalid
    handle_record_invalid(application_attachment)
  rescue ActiveRecord::RecordNotUnique
    unnecessary_error('application')
  rescue ActiveRecord::RecordNotFound
    not_found_error('application')
  end

  def notify_recipient
    return if job.user.eql? user

    ApplicationNotification.with(
      application: %i[user_id
                      job_id], job:
    ).deliver_later(job.user)
  end

  def notify_applicant(new_status, new_response)
    #    return unless job.user.eql? user
    ApplicationStatusNotification.with(application: %i[user_id job_id], user:, job:, status: new_status,
                                       response: new_response).deliver_later(user)
  end

  def accept(response)
    notify_applicant(1, response)
    Application.where(user_id:, job_id:).update_all(
      status: 1, response:
    )
  end

  def reject(response)
    notify_applicant(-1, response)
    Application.where(user_id:, job_id:).update_all(
      status: -1, response:
    )
  end

  private

  def create_application_attachment(user_id, job_id, params)
    application_attachment = ApplicationAttachment.create!(
      user_id:,
      job_id: job_id.to_i
    )

    if params[:application_attachment].present?
      application_attachment.cv.attach(params[:application_attachment])
      application_attachment.save!
    end

    application_attachment
  end

  def create_application(user_id, job, params, _application_attachment)
    application = Application.create!(
      user_id:,
      job_id: job.id,
      application_text: params[:application_text],
      application_documents: 'empty',
      created_at: Time.now,
      updated_at: Time.now,
      response: 'No response yet ...'
    )

    application.user = User.find(user_id)
    application.job = job
    render status: 200,
           json: { "message": 'Application submitted!' }
  end

  def handle_record_invalid(application_attachment)
    application_attachment.destroy if application_attachment.present?
    render status: 400,
           json: { "message": 'Application could not be submitted due to invalid file attachment' }
  end

  def cleanup_notifications
    notifications_as_application.destroy_all
  end
end
