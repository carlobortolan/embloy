# frozen_string_literal: true

# The User class represents a user in the application.
class User < ApplicationRecord
  include SubscriptionStatus

  has_secure_password
  enum :user_type, { company: 'company', user_private: 'private' }, default: 'private'
  enum :user_role, { admin: 'admin', editor: 'editor', developer: 'developer', moderator: 'moderator', verified: 'verified', spectator: 'spectator' }, default: :spectator
  has_one :preferences, dependent: :delete
  has_one_attached :image_url
  has_many :jobs, dependent: :delete_all
  has_many :tokens, dependent: :delete_all
  has_many :reviews, dependent: :delete_all
  has_many :notifications, as: :recipient,
                           dependent: :destroy
  has_many :applications

  pay_customer default_payment_processor: :stripe
  pay_customer stripe_attributes: :stripe_attributes

  validates :email, presence: { error: 'ERR_BLANK', description: "Attribute can't be blank" },
                    uniqueness: { error: 'ERR_TAKEN', description: 'Attribute exists' },
                    format: { with: /\A[^@\s]+@[^@\s]+\z/, error: 'ERR_INVALID', description: 'Attribute is malformed or unknown' },
                    length: { maximum: 150, error: 'ERR_LENGTH', description: 'Attribute length is invalid' }

  validates :first_name, presence: { error: 'ERR_BLANK', description: "Attribute can't be blank" },
                         uniqueness: false,
                         length: { maximum: 128, error: 'ERR_LENGTH', description: 'Attribute length is invalid' }
  validates :last_name, presence: { error: 'ERR_BLANK', description: "Attribute can't be blank" },
                        uniqueness: false,
                        length: { maximum: 128, error: 'ERR_LENGTH', description: 'Attribute length is invalid' }

  validates :password, presence: { error: 'ERR_BLANK', description: "Attribute can't be blank", if: :password_required? },
                       length: { minimum: 8, maximum: 72, error: 'ERR_LENGTH', description: 'Attribute length is invalid', if: :password_required? }
  validates :password_confirmation, presence: { error: 'ERR_BLANK', description: "Attribute can't be blank", if: :password_required? },
                                    length: { minimum: 8, maximum: 72, error: 'ERR_LENGTH', description: 'Attribute length is invalid', if: :password_required? }
  # validates :application_notifications, presence: { error: 'ERR_BLANK', description: "Attribute can't be blank" }
  # validates :communication_notifications, presence: { error: 'ERR_BLANK', description: "Attribute can't be blank" }
  # validates :marketing_notifications, presence: { error: 'ERR_BLANK', description: "Attribute can't be blank" }
  # validates :security_notifications, presence: { error: 'ERR_BLANK', description: "Attribute can't be blank" }
  validates :longitude, presence: false
  validates :latitude, presence: false
  validates :country_code, presence: false
  validates :postal_code, presence: false
  validates :city, presence: false
  validates :address, presence: false, length: { maximum: 150, error: 'ERR_LENGTH', description: 'Attribute length is invalid' }
  validates :linkedin_url, presence: false, length: { maximum: 150, error: 'ERR_LENGTH', description: 'Attribute length is invalid' }
  validates :instagram_url, presence: false, length: { maximum: 150, error: 'ERR_LENGTH', description: 'Attribute length is invalid' }
  validates :twitter_url, presence: false, length: { maximum: 150, error: 'ERR_LENGTH', description: 'Attribute length is invalid' }
  validates :facebook_url, presence: false, length: { maximum: 150, error: 'ERR_LENGTH', description: 'Attribute length is invalid' }
  validates :phone, presence: false, length: { maximum: 100, error: 'ERR_LENGTH', description: 'Attribute length is invalid' }
  # validates :user_type, inclusion: { in: %w[company private], message: 'ERR_INVALID', description: 'Attribute is invalid' }, presence: false
  validates :user_role, inclusion: { in: %w[admin editor developer moderator verified spectator], error: 'ERR_INVALID', description: 'Attribute is invalid' }, presence: false
  validates :image_url, presence: false
  validate :validate_image_size
  validate :country_code_validation
  validate :image_format_validation

  def full_name
    "#{first_name} #{last_name}"
  end

  # Returns the age of the user.
  def age
    return unless date_of_birth

    years_since_birth - (birthday_has_passed? ? 0 : 1)
  end

  # Current approach; - TODO: @cb find easier way to serialize job JSONs & remove commented code when switching to S3
  # Returns a JSON representation of the user.
  def self.json_for(user)
    return unless user

    user_hash = user.to_hash_except_image_url
    user_hash['image_url'] = user.image_url_or_default
    user_hash.to_json
  end

  def to_hash_except_image_url
    JSON.parse(to_json(except: [:image_url]))
  end

  def image_url_or_default
    return image_url.url if image_url.url

    'https://avatars.githubusercontent.com/u/132399266' if !image_url.url.nil? && image_url.attached?
  rescue Fog::Errors::Error
    'https://avatars.githubusercontent.com/u/132399266'
  end

  private

  def stripe_attributes(pay_customer)
    {
      address: {
        city: pay_customer.owner.city,
        country: pay_customer.owner.country_code,
        postal_code: pay_customer.owner.postal_code,
        line1: pay_customer.owner.address
      },
      metadata: {
        pay_customer_id: pay_customer.id,
        user_id: id
      }
    }
  end

  def years_since_birth
    Time.now.utc.to_date.year - date_of_birth.year
  end

  def birthday_has_passed?
    now = Time.now.utc.to_date
    now.month > date_of_birth.month || (now.month == date_of_birth.month && now.day >= date_of_birth.day)
  end

  def password_required?
    password.present? || password_confirmation.present? || new_record?
  end

  def country_code_validation
    return if country_code.nil? || country_code.empty? || IsoCountryCodes.find(country_code)

    errors.add(:country_code,
               'is not a valid ISO country code')
  end

  def image_format_validation
    return unless !image_url.nil? && image_url.attached?

    allowed_formats = %w[image/png image/jpeg
                         image/jpg]
    return if allowed_formats.include?(image_url.blob.content_type)

    errors.add(:image_url,
               { error: 'ERR_INVALID',
                 description: 'must be a PNG, JPG, or JPEG image' })
  end

  def password_validation
    return unless password_required?

    password == password_confirmation
  end

  def validate_image_size
    return unless image_url.attached? && image_url.blob.byte_size > 2.megabytes

    image_url.purge
    errors.add(:image_url, { error: 'ERR_INVALID', description: 'is too large (max is 2 MB)' })
  end
end
