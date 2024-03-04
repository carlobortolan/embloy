# frozen_string_literal: true

# The ApplicationAttachment class represents an attachment (like a CV)
# that is associated with a job application in the application.
class ApplicationAttachment < ApplicationRecord
  belongs_to :job
  belongs_to :user
  has_one_attached :cv, dependent: :destroy
  validate :cv_format_validation
  validate :validate_cv_size

  def validate_cv_size
    return unless cv.attached? && cv.blob.byte_size > 2.megabytes

    cv.purge
    errors.add(:cv, { error: 'ERR_INVALID', description: 'is too large (max is 2 MB)' })
  end

  def cv_format_validation
    return unless cv_attached_and_required?

    allowed_formats = ApplicationHelper.allowed_cv_formats_for_form(job.allowed_cv_formats)
    return if allowed_formats.include?(cv.content_type)

    cv.purge
    errors.add(:cv, { error: 'ERR_INVALID', description: "must be a #{job.allowed_cv_formats.join(',')} file" })
  end

  private

  def cv_attached_and_required?
    cv.attached? && job.cv_required && !job.allowed_cv_formats.nil?
  end
end
