class Job < ApplicationRecord
  include Visible
  # Job.ms_search("finance", filter: ["job_type=sales"], sort: ["created_at:desc"])
  include MeiliSearch::Rails
  meilisearch do
    displayed_attributes [:id, :title, :description, :start_slot, :position, :key_skills, :salary, :job_type, :created_at, :updated_at]
    searchable_attributes [:title, :description, :start_slot, :position, :key_skills, :salary, :job_type]
    filterable_attributes [:job_type]
    sortable_attributes [:created_at, :salary]
  end

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
  validates :job_type, presence: { "error": "ERR_BLANK", "description": "Attribute can't be blank" }
  validates :job_type_value, presence: { "error": "ERR_BLANK", "description": "Attribute can't be blank" }
  validate :job_type_verification
  validate :employer_rating
  validate :boost

  def profile
    @job.update(view_count: @job.view_count + 1)
  end

  def reject_all
    self.applications.each { |application| application.reject("REJECTED") }
  end

  def format_address
    "#{self.address}, #{self.city}, #{self.postal_code}, #{self.country_code}"
    if self.address.nil? || self.city.nil? || self.postal_code.nil? || self.country_code.nil?
      "No location details available."
    else
      "#{self.address}, #{self.city}, #{self.postal_code}, #{self.country_code}"
    end
  end

  def job_type_verification
    job_types_file = File.read(Rails.root.join("app/helpers", "job_types.json"))
    job_types = JSON.parse(job_types_file)

    unless job_types.key?(job_type)
      errors.add(:job_type, { "error": "ERR_INVALID", "description": "Attribute is malformed or unknown" })
    end
  end
end
