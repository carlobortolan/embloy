# frozen_string_literal: true

# rubocop:disable Metrics/ModuleLength
# The JobValidator module contains custom validation rules for a Job object.
module Validators
  # These rules are included in the Job model and run when a Job object is saved.
  module JobValidator
    extend ActiveSupport::Concern
    # rubocop:disable Metrics/BlockLength
    included do
      geocoded_by :latitude_longitude
      after_validation :geocode
      include PgSearch::Model
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
      has_many :application_options, dependent: :destroy
      accepts_nested_attributes_for :application_options, allow_destroy: true
      has_noticed_notifications model_name: 'Notification'
      has_rich_text :description
      has_one_attached :image_url

      validates :job_slug, uniqueness: { scope: :user_id, error: 'ERR_UNIQUE', description: 'Should be unique per user' }, on: %i[create update]
      validates :title, length: { minimum: 0, maximum: 100, error: 'ERR_LENGTH', description: 'Attribute length is invalid' }, allow_blank: true
      validates :description, length: { minimum: 10, maximum: 10_000, error: 'ERR_LENGTH', description: 'Attribute length is invalid' }, allow_blank: true
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
      validates :job_status, inclusion: { in: %w[listed unlisted archived], error: 'ERR_INVALID', description: 'Attribute is invalid' }, presence: false

      validates :longitude, presence: { error: 'ERR_BLANK', description: "Attribute can't be blank" },
                            numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180, error: 'ERR_INVALID', description: 'Attribute is malformed or unknown' }
      validates :latitude, presence: { error: 'ERR_BLANK', description: "Attribute can't be blank" },
                           numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90, error: 'ERR_INVALID', description: 'Attribute is malformed or unknown' }
      # validates :postal_code, length: { minimum: 0, maximum: 45, "error": "ERR_LENGTH", "description": "Attribute length is invalid" }
      # validates :country_code, length: { minimum: 0, maximum: 45, "error": "ERR_LENGTH", "description": "Attribute length is invalid" }
      # validates :city, length: { minimum: 0, maximum: 45, "error": "ERR_LENGTH", "description": "Attribute length is invalid" }
      # validates :address, length: { minimum: 0, maximum: 150, "error": "ERR_LENGTH", "description": "Attribute length is invalid" }
      validate :employer_rating
      validate :boost
      validate :start_slot_validation
      validate :job_type_validation
      validate :image_format_validation
      validate :validate_image_size
      validate :application_options_count_validation
      validate :application_options_validity
      validate :check_subscription_limit_create, on: :create
      validate :check_subscription_limit_update, on: :update
    end

    private

    def check_subscription_limit_create
      return unless user
      return unless user.user_type == 'sandbox'
      return unless user.jobs.where(job_status: %w[listed unlisted], activity_status: 1).count >= max_jobs_allowed

      raise CustomExceptions::Subscription::LimitReached
    end

    def check_subscription_limit_update
      return unless user
      return unless user.user_type == 'sandbox'
      return unless user.jobs.where(job_status: %w[listed unlisted], activity_status: 1).count > max_jobs_allowed

      raise CustomExceptions::Subscription::LimitReached
    end

    def max_jobs_allowed
      subscription = user.current_subscription
      subscription_type = subscription ? SubscriptionHelper.subscription_type(subscription.processor_plan) : nil

      case subscription_type
      when 'basic'
        3
      when 'premium'
        50
      when 'enterprise_1', 'enterprise_2', 'enterprise_3'
        Float::INFINITY
      else
        0
      end
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

    def validate_image_size
      return unless image_url.attached? && image_url.blob.byte_size > 2.megabytes

      image_url.purge
      errors.add(:image_url, { error: 'ERR_INVALID', description: 'is too large (max is 2 MB)' })
    end

    def application_options_count_validation
      return if application_options.size <= 50

      errors.add(:application_options, 'A job can have at most 50 application options')
    end

    def application_options_validity
      application_options.each do |application_option|
        application_option.errors.full_messages.each do |message|
          errors.add(:application_options, message)
        end
      end
    end
    # rubocop:enable Metrics/BlockLength
  end
end
# rubocop:enable Metrics/ModuleLength
