# frozen_string_literal: true

# The JobValidator module contains custom validation rules for a Job object.
module Validators
  # These rules are included in the Job model and run when a Job object is saved.
  module JobValidator
    extend ActiveSupport::Concern

    # rubocop:disable Metrics/BlockLength
    included do
      geocoded_by :latitude_longitude
      after_validation :geocode
      include Visible
      include PgSearch::Model
      # include ActiveModel::Serialization
      paginates_per 48
      max_pages 10
      multisearchable against: %i[title job_type
                                  position key_skills description city postal_code address]
      pg_search_scope :search_for,
                      against: %i[title description position job_type key_skills address city postal_code
                                  start_slot],
                      using: {
                        tsearch: { prefix: true,
                                   any_word: true, dictionary: 'english', normalization: 2 },
                        trigram: { threshold: 0.1 }
                      }
      scope :within_radius, lambda { |lat, lng, rad, lim|
        select("*, ST_Distance(job_value::geometry, ST_SetSRID(ST_MakePoint(#{lat}, #{lng}), 4326)::geography) AS distance")
          .where("ST_DWithin(job_value::geometry, ST_SetSRID(ST_MakePoint(#{lat}, #{lng}), 4326)::geography, #{rad})")
          .order('distance')
          .limit(lim)
      }
      belongs_to :user, counter_cache: true
      has_many :applications, dependent: :delete_all
      has_many :application_attachments,
               dependent: :delete_all
      has_noticed_notifications model_name: 'Notification'
      has_rich_text :description
      has_one_attached :image_url

      validates :job_slug, uniqueness: { scope: :user_id, error: 'ERR_BLANK', description: 'Should be unique per user' }
      validates :title, length: { minimum: 0, maximum: 100, error: 'ERR_LENGTH', description: 'Attribute length is invalid' }, allow_blank: true
      validates :description, length: { minimum: 10, maximum: 1000, error: 'ERR_LENGTH', description: 'Attribute length is invalid' }, allow_blank: true
      validates :longitude, presence: { error: 'ERR_BLANK', description: "Attribute can't be blank" },
                            numericality: { error: 'ERR_INVALID', description: 'Attribute is malformed or unknown' }
      validates :latitude, presence: { error: 'ERR_BLANK', description: "Attribute can't be blank" },
                           numericality: { error: 'ERR_INVALID', description: 'Attribute is malformed or unknown' }
      validates :job_notifications, inclusion: { in: %w[0 1], error: 'ERR_INVALID', description: 'Attribute is malformed or unknown' }, allow_blank: true
      validates :position, length: { minimum: 0, maximum: 100, error: 'ERR_LENGTH', description: 'Attribute length is invalid' }, allow_blank: true
      validates :key_skills, length: { minimum: 0, maximum: 100, error: 'ERR_LENGTH', description: 'Attribute length is invalid' }, allow_blank: true
      validates :duration, numericality: { only_integer: true, greater_than: 0, error: 'ERR_INVALID', description: 'Attribute is malformed or unknown' }
      validates :salary, numericality: { only_integer: true, greater_than: 0, error: 'ERR_INVALID', description: 'Attribute is malformed or unknown' }, allow_blank: true
      validates :currency, format: { with: /\A[A-Z]{3}\z/, message: { error: 'ERR_INVALID', description: 'Attribute is malformed or unknown' } }, allow_blank: true
      validates :status, inclusion: { in: %w[public private archived], error: 'ERR_INVALID', description: 'Attribute is invalid' }, presence: false

      validates :longitude, presence: { error: 'ERR_BLANK', description: "Attribute can't be blank" },
                            numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180, error: 'ERR_INVALID', description: 'Attribute is malformed or unknown' }
      validates :latitude, presence: { error: 'ERR_BLANK', description: "Attribute can't be blank" },
                           numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90, error: 'ERR_INVALID', description: 'Attribute is malformed or unknown' }
      # validates :postal_code, length: { minimum: 0, maximum: 45, "error": "ERR_LENGTH", "description": "Attribute length is invalid" }
      # validates :country_code, length: { minimum: 0, maximum: 45, "error": "ERR_LENGTH", "description": "Attribute length is invalid" }
      # validates :city, length: { minimum: 0, maximum: 45, "error": "ERR_LENGTH", "description": "Attribute length is invalid" }
      # validates :address, length: { minimum: 0, maximum: 150, "error": "ERR_LENGTH", "description": "Attribute length is invalid" }
      validate :cv_formats_validation
      validate :employer_rating
      validate :boost
      validate :start_slot_validation
      validate :job_type_validation
      validate :image_format_validation
    end
    # rubocop:enable Metrics/BlockLength

    private

    def cv_formats_validation
      self.allowed_cv_formats = ['.pdf', '.docx', '.txt', '.xml'] if allowed_cv_formats.nil?
      valid_formats = ['.pdf', '.docx', '.txt', '.xml']
      return if !allowed_cv_formats.nil? && allowed_cv_formats.all? { |format| valid_formats.include?(format) }

      errors.add(:allowed_cv_formats, 'Invalid file format. Only PDF, DOCX, TXT, and XML files are allowed.')
    end

    def job_type_validation
      job_types_file = File.read(Rails.root.join('app/helpers', 'job_types.json'))
      job_types = JSON.parse(job_types_file)
      # Given job_type is not existent in job_types.json
      return if job_types.key?(job_type) || job_type.nil?

      errors.add(:job_type, error: 'ERR_INVALID', description: 'Attribute is malformed or unknown')
    end

    def start_slot_validation
      return if start_slot.nil?
      return unless start_slot < Time.now

      errors.add(:start_slot, { error: 'ERR_INVALID', description: 'Attribute is malformed or unknown' })
    end

    def image_format_validation
      return unless image_url.attached?

      allowed_formats = ['image/png', 'image/jpeg', 'image/jpg']
      return if allowed_formats.include?(image_url.content_type)

      errors.add(:image_url, { error: 'ERR_INVALID', description: 'must be a PNG, JPG, or JPEG image' })
    end
  end
end
