# frozen_string_literal: true

# Represents a special User class used for company users
class CompanyUser < User
  include Rails.application.routes.url_helpers
  include Dao::CompanyUserDao

  has_rich_text :company_description
  has_one_attached :company_logo

  validates :company_slug, uniqueness: { error: 'ERR_UNIQUE', description: 'Should be unique' }, on: %i[create update],
                           length: { maximum: 128, error: 'ERR_LENGTH', description: 'Attribute length is invalid' },
                           allow_blank: true
  validates :company_phone, length: { maximum: 20, error: 'ERR_LENGTH', description: 'Attribute length is invalid' }, allow_blank: true
  validates :company_email, uniqueness: { error: 'ERR_TAKEN', description: 'Attribute exists' },
                            format: { with: /\A[^@\s]+@[^@\s]+\z/, error: 'ERR_INVALID', description: 'Attribute is malformed or unknown' },
                            length: { maximum: 150, error: 'ERR_LENGTH', description: 'Attribute length is invalid' },
                            allow_blank: true
  validates :company_description, length: { minimum: 10, maximum: 10_000, error: 'ERR_LENGTH', description: 'Attribute length is invalid' }, allow_blank: true
  validates :company_urls, length: { maximum: 10, error: 'ERR_LENGTH', description: 'Attribute length is invalid' }, allow_blank: true
  validates :company_industry, length: { maximum: 150, error: 'ERR_LENGTH', description: 'Attribute length is invalid' }, allow_blank: true
  validate :logo_format_validation
  validate :validate_logo_size
  validate :validate_company_urls
  before_save :set_default_company_slug, if: -> { company_slug.nil? }
  before_save :parse_company_urls

  def self.check_attributes(company_attributes, check_missing: true)
    errors = []
    required_keys = %w[company_name company_email company_slug company_logo]
    required_keys.each do |key|
      if check_missing
        errors << { error: 'ERR_MISSING', description: "The key '#{key}' is missing" } and next unless company_attributes.key?(key)

        errors << { error: 'ERR_BLANK', description: "The key '#{key}' can't be blank" } if company_attributes[key].blank?
      elsif company_attributes.key?(key) && company_attributes[key].blank?
        errors << { error: 'ERR_BLANK', description: "The key '#{key}' can't be blank" }
      end
    end
    errors.empty? ? nil : errors
  end

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

  def validate_company_urls
    if company_urls.nil? || (company_urls.is_a?(Array) && company_urls.all?(&:blank?))
      self.company_urls = nil
      return
    end

    return if company_urls.is_a?(Array) && company_urls.all? { |url| url =~ /\A#{URI::DEFAULT_PARSER.make_regexp(%w[http https])}\z/ }

    errors.add(:company_urls, { error: 'ERR_INVALID', description: 'must be an array of valid URLs' })
  end

  def parse_company_urls
    self.company_urls = JSON.parse(company_urls) if company_urls.is_a?(String) && company_urls.start_with?('[')
  end

  def set_default_company_slug
    self.company_slug = SecureRandom.uuid
  end
end
