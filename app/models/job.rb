class Job < ApplicationRecord
  include Visible
  belongs_to :user, counter_cache: true

  has_many :applications, dependent: :delete_all
  # has_many :notifications, dependent: :delete_all
  # has_many :notifications, through: :user, dependent: :delete_all
  has_noticed_notifications model_name: 'Notification'

  has_rich_text :content
  validates :title, presence: { "error": "ERR_BLANK", "description": "Attribute can't be blank" }
  validates :description, presence: { "error": "ERR_BLANK", "description": "Attribute can't be blank" }, length: { minimum: 10 }
  validates :start_slot, presence: { "error": "ERR_BLANK", "description": "Attribute can't be blank" }
  validates :longitude, presence: { "error": "ERR_BLANK", "description": "Attribute can't be blank" }
  validates :latitude, presence: { "error": "ERR_BLANK", "description": "Attribute can't be blank" }
  validates :job_notifications, presence: { "error": "ERR_BLANK", "description": "Attribute can't be blank" }
  validates :position, presence: { "error": "ERR_BLANK", "description": "Attribute can't be blank" }
  validates :key_skills, presence: { "error": "ERR_BLANK", "description": "Attribute can't be blank" }
  validates :duration, presence: { "error": "ERR_BLANK", "description": "Attribute can't be blank" }
  validates :salary, presence: { "error": "ERR_BLANK", "description": "Attribute can't be blank" }
  validates :currency, presence: { "error": "ERR_BLANK", "description": "Attribute can't be blank" }
  #TODO: @cb make front end job_type submit work -> Then activate verification blow
  #validates :job_type, presence: { "error": "ERR_BLANK", "description": "Attribute can't be blank" }

  def profile
    @job.update(view_count: @job.view_count + 1)
  end

  def reject_all
    self.applications.each { |application| application.reject("REJECTED") }
  end

  def format_addeess
    "#{self.address}, #{self.city}, #{self.postal_code}, #{self.country_code}"
    if self.address.nil? || self.city.nil? || self.postal_code.nil? || self.country_code.nil?
      "No location details available."
    else
      "#{self.address}, #{self.city}, #{self.postal_code}, #{self.country_code}"
    end
  end

end
