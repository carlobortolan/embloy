class ApplicationAttachment < ApplicationRecord
  # belongs_to :application, counter_cache: true, :dependent => :destroy
  belongs_to :job
  belongs_to :user
  validate :cv_format_validation
  has_one_attached :cv, dependent: :destroy

  def cv_format_validation
    return unless !cv.nil? && cv.attached?
    allowed_formats = %w[application/pdf text/plain application/vnd.openxmlformats-officedocument.wordprocessingml.document text/xml]
    unless allowed_formats.include?(cv.blob.content_type)
      errors.add(:cv, { "error": "ERR_INVALID", "description": "must be a #{job.allowed_cv_format.join(',')} file" })
    end
  end

end
