# frozen_string_literal: true

# The Job class represents a job in the application.
# It includes methods for creating, updating, and deleting jobs,
# as well as other helper methods related to jobs.
class Job < ApplicationRecord
  include Validators::JobValidator
  include Dao::JobDao

  VALID_JOB_TYPES = %w[listed unlisted archived].freeze

  before_save :set_default_job_slug, if: -> { job_slug.nil? }
  before_validation :set_default_values
  acts_as_paranoid
  enum :job_status, { listed: 'listed', unlisted: 'unlisted', archived: 'archived' }, default: 'listed' # include ActiveModel::Serialization

  TIME_UNITS = {
    0...60 => :less_than_a_minute,
    60...(60 * 60) => :minutes_left,
    (60 * 60)...(60 * 60 * 24) => :hours_left,
    (60 * 60 * 24)...(60 * 60 * 24 * 7) => :days_left,
    (60 * 60 * 24 * 7)...(60 * 60 * 24 * 30) => :weeks_left
  }.freeze

  def profile
    @job.update(view_count: @job.view_count + 1)
  end

  def latitude_longitude
    [latitude, longitude].join(',')
  end

  def time_left
    diff_seconds = (start_slot - Time.zone.now).to_i
    return 'deadline passed' if diff_seconds.negative?

    calculate_time_left(diff_seconds)
  end

  def reject_all
    applications.each do |application|
      application.reject('REJECTED')
    end
  end

  def format_address
    if address.nil? || city.nil? || postal_code.nil? || country_code.nil?
      'No location details available.'
    else
      "#{address}, #{city}, #{postal_code}, #{country_code}"
    end
  end

  def assign_job_type_value
    job_types = JSON.parse(File.read(Rails.root.join('app/helpers', 'job_types.json')))
    self.job_type_value = job_types[job_type]
  end

  def from_lever?
    job_slug&.start_with?('lever__') || referrer_url&.include?('jobs.lever.co') || referrer_url&.include?('jobs.sandbox.lever.co')
  end

  def from_ashby?
    job_slug&.start_with?('ashby__') || referrer_url&.include?('app.ashbyhq.com')
  end

  def duplicate_application_allowed?
    from_lever? || from_ashby? || Current.user.sandboxd? || Current.user.admin?
  end

  private

  def calculate_time_left(diff_seconds)
    time_unit = TIME_UNITS.find { |range, _| range.include?(diff_seconds) }
    return 'in more than a month' unless time_unit

    send(time_unit.last, diff_seconds)
  end

  def less_than_a_minute(_diff_seconds)
    'in less than a minute'
  end

  def minutes_left(diff_seconds)
    "in #{diff_seconds / 60} minute#{'s' if diff_seconds / 60 > 1}"
  end

  def hours_left(diff_seconds)
    "in #{diff_seconds / 3600} hour#{'s' if diff_seconds / 3600 > 1}"
  end

  def days_left(diff_seconds)
    "in #{diff_seconds / 86_400} day#{'s' if diff_seconds / 86_400 > 1}"
  end

  def weeks_left(diff_seconds)
    "in #{diff_seconds / 604_800} week#{'s' if diff_seconds / 604_800 > 1}"
  end

  def set_default_job_slug
    self.job_slug = SecureRandom.uuid
  end

  def set_default_values
    self.longitude ||= 0.0
    self.latitude ||= 0.0
    self.duration = 0 if duration.nil?
    self.duration = duration.zero? ? 1 : duration
  end
end
