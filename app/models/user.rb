class User < ApplicationRecord
  has_secure_password

  has_one :preferences, dependent: :delete
  has_one_attached :image_url
  has_many :jobs, dependent: :delete_all
  has_many :reviews, dependent: :delete_all
  has_many :notifications, as: :recipient, dependent: :destroy
  has_many :applications
  has_many :application_attachments
  has_many :subscriptions, dependent: :delete_all

  validates :email, presence: { "error": "ERR_BLANK", "description": "Attribute can't be blank" },
            uniqueness: { "error": "ERR_TAKEN", "description": "Attribute exists" },
            format: { with: /\A[^@\s]+@[^@\s]+\z/, "error": "ERR_INVALID", "description": "Attribute is malformed or unknown" }
  validates :first_name, presence: { "error": "ERR_BLANK", "description": "Attribute can't be blank" }, uniqueness: false
  validates :last_name, presence: { "error": "ERR_BLANK", "description": "Attribute can't be blank" }, uniqueness: false
  validates :password, presence: { "error": "ERR_BLANK", "description": "Attribute can't be blank", if: :password_required? },
            length: { minimum: 8, maximum: 72, "error": "ERR_LENGTH", "description": "Attribute length is invalid", if: :password_required? }
  validates :password_confirmation, presence: { "error": "ERR_BLANK", "description": "Attribute can't be blank", if: :password_required? },
            length: { minimum: 8, maximum: 72, "error": "ERR_LENGTH", "description": "Attribute length is invalid", if: :password_required? }
  # allow_nil: false,
  # allow_blank: false
  validates :application_notifications, presence: { "error": "ERR_BLANK", "description": "Attribute can't be blank" }
  validates :longitude, presence: false
  validates :latitude, presence: false
  validates :country_code, presence: false
  validates :postal_code, presence: false
  validates :city, presence: false
  validates :address, presence: false
  validates :user_type, inclusion: { in: %w[company private], "error": "ERR_INVALID", "description": "Attribute is invalid" }, presence: false
  validates :user_role, inclusion: { in: %w[admin editor developer moderator verified spectator], "error": "ERR_INVALID", "description": "Attribute is invalid" }, presence: false
  validates :image_url, presence: false

  validate :country_code_validation
  validate :image_format_validation

  def full_name
    "#{first_name} #{last_name}"
  end

  def is_verified?
    [true, false].sample
  end

  def age
    now = Time.now.utc.to_date
    now.year - self.date_of_birth.year - ((now.month > self.date_of_birth.month || (now.month == self.date_of_birth.month && now.day >= self.date_of_birth.day)) ? 0 : 1) unless self.date_of_birth.nil?
  end

  # Current approach; - TODO: @cb find easier way to serialize job JSONs & remove commented code when switching to S3
  def self.get_json(user)
    unless user.nil?
      begin
        unless user.image_url.url.nil?
          # Parse the JSON to a hash
          res_hash = JSON.parse(user.to_json(except: [:image_url]))
          # Add the 'image_url' field with the value 'user.image_url.url'
          res_hash['image_url'] = user.image_url.url
          res_hash.to_json
        else
          JSON.parse(user.to_json(except: [:image_url])).to_json
        end
      rescue Fog::Errors::Error
        res_hash = JSON.parse(user.to_json(except: [:image_url]))
        res_hash['image_url'] = "https://embloy.onrender.com/assets/img/features_3.png"
        res_hash.to_json
      end
    end
  end

  private

  def password_required?
    password.present? || password_confirmation.present? || new_record?
  end

  def country_code_validation
    unless country_code.nil? || country_code.empty? || IsoCountryCodes.find(country_code)
      errors.add(:country_code, "is not a valid ISO country code")
    end
  end

  def image_format_validation
    return unless !image_url.nil? && image_url.attached?
    allowed_formats = %w[image/png image/jpeg image/jpg]
    unless allowed_formats.include?(image_url.blob.content_type)
      errors.add(:image_url, { "error": "ERR_INVALID", "description": "must be a PNG, JPG, or JPEG image" })
    end
  end

  def password_validation
    if password_required?
      password == password_confirmation
    end
  end

end