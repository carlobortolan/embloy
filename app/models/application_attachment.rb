class ApplicationAttachment < ApplicationRecord
  # belongs_to :application, counter_cache: true, :dependent => :destroy
  belongs_to :job
  belongs_to :user
  validate :cv_format_validation
  has_one_attached :cv, dependent: :destroy

  def cv_format_validation
    return unless !cv.nil? && cv.attached? && job.cv_required && !job.allowed_cv_format.nil?
    allowed_formats = ApplicationHelper.allowed_cv_formats_for_form(job.allowed_cv_format)
    unless allowed_formats.include?(cv.blob.content_type)
      errors.add(:cv, { "error": "ERR_INVALID", "description": "must be a #{job.allowed_cv_format.join(',')} file" })
    end
  end

end
