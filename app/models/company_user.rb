# frozen_string_literal: true

# Represents a special User class used for company users
class CompanyUser < User
  validates :company_slug, uniqueness: { error: 'ERR_UNIQUE', description: 'Should be unique' }, on: %i[create update]
  validates :company_name, presence: { error: 'ERR_BLANK', description: "Attribute can't be blank" },
                           length: { maximum: 128, error: 'ERR_LENGTH', description: 'Attribute length is invalid' }

  validates :company_phone, presence: true, length: { maximum: 20, error: 'ERR_LENGTH', description: 'Attribute length is invalid' }

  validates :company_email, presence: { error: 'ERR_BLANK', description: "Attribute can't be blank" },
                            uniqueness: { error: 'ERR_TAKEN', description: 'Attribute exists' },
                            format: { with: /\A[^@\s]+@[^@\s]+\z/, error: 'ERR_INVALID', description: 'Attribute is malformed or unknown' },
                            length: { maximum: 150, error: 'ERR_LENGTH', description: 'Attribute length is invalid' }
  validates :company_url, presence: true, length: { maximum: 150, error: 'ERR_LENGTH', description: 'Attribute length is invalid' }
  validates :company_industry, presence: { error: 'ERR_BLANK', description: "Attribute can't be blank" }
  validates :company_description, presence: { error: 'ERR_BLANK', description: "Attribute can't be blank" }

  has_rich_text :company_description
  has_one_attached :company_logo

  validate :logo_format_validation
  validate :validate_logo_size
  before_save :set_default_company_slug, if: -> { company_slug.nil? }

  private

  def logo_format_validation
    return unless company_logo.attached?

    allowed_formats = %w[image/png image/jpeg image/jpg]
    return if allowed_formats.include?(company_logo.blob.content_type)

    errors.add(:company_logo, { error: 'ERR_INVALID', description: 'must be a PNG, JPG, or JPEG image' })
  end

  def validate_logo_size
    return unless company_logo.attached? && company_logo.blob.byte_size > 2.megabytes

    company_logo.purge
    errors.add(:company_logo, { error: 'ERR_INVALID', description: 'is too large (max is 2 MB)' })
  end

  def set_default_company_slug
    self.company_slug = SecureRandom.uuid
  end
end
