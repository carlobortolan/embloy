# frozen_string_literal: true

# The User class represents a user in the application.
class User < ApplicationRecord
  # STI
  self.inheritance_column = :type
  include SubscriptionStatus
  include Rails.application.routes.url_helpers
  include Dao::UserDao

  has_secure_password
  enum :type, { CompanyUser: 'CompanyUser', PrivateUser: 'PrivateUser', SandboxUser: 'SandboxUser' }, default: 'PrivateUser'
  enum :user_role, { admin: 'admin', editor: 'editor', developer: 'developer', moderator: 'moderator', verified: 'verified', spectator: 'spectator' }, default: :spectator
  has_one :preferences, dependent: :delete
  has_one_attached :image_url
  has_many :jobs, dependent: :delete_all
  has_many :tokens, dependent: :delete_all
  has_many :reviews, dependent: :delete_all
  has_many :notifications, as: :recipient,
                           dependent: :destroy
  has_many :applications
  has_many :webhooks, dependent: :delete_all
  has_many :job_lists, dependent: :destroy

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
  validates :github_url, presence: false, length: { maximum: 150, error: 'ERR_LENGTH', description: 'Attribute length is invalid' }
  validates :portfolio_url, presence: false, length: { maximum: 150, error: 'ERR_LENGTH', description: 'Attribute length is invalid' }
  validates :phone, presence: false, length: { maximum: 100, error: 'ERR_LENGTH', description: 'Attribute length is invalid' }
  validates :user_role, inclusion: { in: %w[admin editor developer moderator verified spectator], error: 'ERR_INVALID', description: 'Attribute is invalid' }, presence: false
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

  def admin?
    user_role == 'admin'
  end

  def switch_to_sandbox!
    return if sandboxd?

    update!(type: 'SandboxUser')
  end

  def switch_to_company(company_attributes)
    return [nil, { type: 'You already have a company account' }] if company?

    err = CompanyUser.check_attributes(company_attributes)
    return [nil, err] if err

    transaction do
      update!(type: 'CompanyUser')

      company_user = CompanyUser.find(id)
      if company_user.update(company_attributes)
        [company_user, nil]
      else
        update!(type: 'PrivateUser') # Rollback type change if update fails
        [nil, company_user.errors]
      end
    end
  rescue ActiveRecord::RecordInvalid => e
    [nil, e.record.errors]
  end

  def switch_to_private!
    return if private?

    update!(
      type: 'PrivateUser',
      company_name: nil,
      company_slug: nil,
      company_phone: nil,
      company_email: nil,
      company_urls: nil,
      company_industry: nil,
      company_description: nil,
      company_logo: nil
    )
  end

  def sandboxd?
    type == 'SandboxUser'
  end

  def company?
    type == 'CompanyUser'
  end

  def private?
    type == 'PrivateUser'
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

    errors.add(:country_code, 'is not a valid ISO country code')
  end

  def image_format_validation
    return unless !image_url.nil? && image_url.attached?

    allowed_formats = %w[image/png image/jpeg image/jpg]
    return if allowed_formats.include?(image_url.blob.content_type)

    errors.add(:image_url, { error: 'ERR_INVALID', description: 'must be a PNG, JPG, or JPEG image' })
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
