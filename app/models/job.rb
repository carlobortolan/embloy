class Job < ApplicationRecord
  geocoded_by :latitude_longitude
  after_validation :geocode
  include Visible
  include PgSearch::Model
  paginates_per 48
  max_pages 10
  multisearchable against: [:title, :job_type, :position, :key_skills, :description, :city, :postal_code, :address]
  pg_search_scope :search_for,
                  against: [:title, :description, :position, :job_type, :key_skills, :address, :city, :postal_code, :start_slot],
                  using: {
                    tsearch: { prefix: true, any_word: true, dictionary: "english", normalization: 2 },
                    trigram: { threshold: 0.1 }
                  }
  scope :within_radius, ->(lat, lng, rad, lim) {
    select("*, ST_Distance(job_value::geometry, ST_SetSRID(ST_MakePoint(#{lat}, #{lng}), 4326)::geography) AS distance").
      where("ST_DWithin(job_value::geometry, ST_SetSRID(ST_MakePoint(#{lat}, #{lng}), 4326)::geography, #{rad})").
      order("distance").
      limit(lim)
  }
  belongs_to :user, counter_cache: true
  has_many :applications, dependent: :delete_all
  has_noticed_notifications model_name: 'Notification'
  has_rich_text :content
  validates :title, presence: { "error": "ERR_BLANK", "description": "Attribute can't be blank" }
  validates :description, presence: { "error": "ERR_BLANK", "description": "Attribute can't be blank" }, length: { minimum: 10 }
  validates :start_slot, presence: { "error": "ERR_BLANK", "description": "Attribute can't be blank" }
  validates :longitude, presence: { "error": "ERR_BLANK", "description": "Attribute can't be blank" }, :numericality => { "error": "ERR_INVALID", "description": "Attribute is malformed or unknown" }
  validates :latitude, presence: { "error": "ERR_BLANK", "description": "Attribute can't be blank" }, :numericality => { "error": "ERR_INVALID", "description": "Attribute is malformed or unknown" }

  validates :job_notifications, presence: { "error": "ERR_BLANK", "description": "Attribute can't be blank" }, :numericality => { only_integer: true, "error": "ERR_INVALID", "description": "Attribute is malformed or unknown" }
  validates :position, presence: { "error": "ERR_BLANK", "description": "Attribute can't be blank" }
  validates :key_skills, presence: { "error": "ERR_BLANK", "description": "Attribute can't be blank" }
  validates :duration, presence: { "error": "ERR_BLANK", "description": "Attribute can't be blank" }, :numericality => { only_integer: true, greater_than: 0, "error": "ERR_INVALID", "description": "Attribute is malformed or unknown" }
  validates :salary, presence: { "error": "ERR_BLANK", "description": "Attribute can't be blank" }, :numericality => { only_integer: true, greater_than: 0, "error": "ERR_INVALID", "description": "Attribute is malformed or unknown" }
  validates :currency, presence: { "error": "ERR_BLANK", "description": "Attribute can't be blank" }
  validates :job_type, presence: { "error": "ERR_BLANK", "description": "Attribute can't be blank" }
  validates :job_type_value, presence: { "error": "ERR_BLANK", "description": "Attribute can't be blank" }
  validate :job_type_verification
  validate :employer_rating
  validate :boost
  validate :start_slot_validation

  def profile
    @job.update(view_count: @job.view_count + 1)
  end

  def latitude_longitude
    [latitude, longitude].join(',')
  end

  def time_left
    diff_seconds = (start_slot - Time.zone.now).to_i

    case
    when diff_seconds < 0
      return "deadline passed"
    when diff_seconds < 60
      return "in less than a minute"
    when diff_seconds < 60 * 60
      return "in #{diff_seconds / 60} minute#{'s' if diff_seconds / 60 > 1}"
    when diff_seconds < 60 * 60 * 24
      return "in #{diff_seconds / 3600} hour#{'s' if diff_seconds / 3600 > 1}"
    when diff_seconds < 60 * 60 * 24 * 7
      return "in #{diff_seconds / 86400} day#{'s' if diff_seconds / 86400 > 1}"
    when diff_seconds < 60 * 60 * 24 * 30
      return "in #{diff_seconds / 604800} week#{'s' if diff_seconds / 604800 > 1}"
    else
      return "in more than a month"
    end
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
    # Given job_type is not existent in job_types.json
    unless job_types.key?(job_type)
      errors.add(:job_type, { "error": "ERR_INVALID", "description": "Attribute is malformed or unknown" })
    end
  end

  def start_slot_validation
    begin
      if start_slot - Time.now < -86400
        errors.add(:start_slot, { "error": "ERR_INVALID", "description": "Attribute is malformed or unknown" })
      end
    end
  end

end

