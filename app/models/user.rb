class User < ApplicationRecord
  has_secure_password
  has_many :jobs, dependent: :delete_all
  has_many :reviews, dependent: :delete_all
  has_many :notifications, as: :recipient, dependent: :destroy

  validates :email, presence: { "error": "ERR_BLANK", "description": "Attribute can't be blank" }, uniqueness: { "error": "ERR_TAKEN", "description": "Attribute exists" }, format: { with: /\A[^@\s]+@[^@\s]+\z/, "error": "ERR_INVALID", "description": "Attribute is malformed or unknown" }
  validates :first_name, presence: { "error": "ERR_BLANK", "description": "Attribute can't be blank" }, uniqueness: false
  validates :last_name, presence: { "error": "ERR_BLANK", "description": "Attribute can't be blank" }, uniqueness: false
  # TODO: UNDERSTAND UPDATABLE?
  # validates :password, presence: { "error": "ERR_BLANK", "description": "Attribute can't be blank" }, uniqueness: false, length: { minimum: 8, maximum: 72 }
  validates :application_notifications, presence: true
  validates :longitude, presence: false
  validates :latitude, presence: false
  validates :country_code, presence: false
  validates :postal_code, presence: false
  validates :city, presence: false
  validates :address, presence: false
  validates :user_type, presence: false
  validates :image_url, presence: false

  def full_name
    "#{first_name} #{last_name}"
  end

  def age
    now = Time.now.utc.to_date
    now.year - self.date_of_birth.year - ((now.month > self.date_of_birth.month || (now.month == self.date_of_birth.month && now.day >= self.date_of_birth.day)) ? 0 : 1) unless self.date_of_birth.nil?
  end

end