# frozen_string_literal: true

# The Job class represents a job in the application.
# It includes methods for creating, updating, and deleting jobs,
# as well as other helper methods related to jobs.
class Job < ApplicationRecord
  include Validators::JobValidator
  before_save :set_default_job_slug, if: -> { job_slug.nil? }
  before_validation :set_default_values
  acts_as_paranoid

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

  def self.json_for(job)
    Serializers::JobSerializer.json_for(job)
  end

  def self.get_json_include_user(job)
    Serializers::JobSerializer.get_json_include_user(job)
  end

  def self.get_json_include_user_exclude_image(job)
    Serializers::JobSerializer.get_json_include_user_exclude_image(job)
  end

  def self.jsons_for(jobs)
    Serializers::JobSerializer.jsons_for(jobs)
  end

  def self.get_jsons_include_user(jobs)
    Serializers::JobSerializer.get_jsons_include_user(jobs)
  end

  def assign_job_type_value
    job_types = JSON.parse(File.read(Rails.root.join('app/helpers', 'job_types.json')))
    self.job_type_value = job_types[job_type]
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
    self.duration = duration.zero? ? 1 : duration
  end
end
