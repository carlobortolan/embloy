# frozen_string_literal: true

# The Preferences class represents a user's preferences in the application.
class Preferences < ApplicationRecord
  belongs_to :user, dependent: :destroy

  validates :interests, presence: false
  validates :experience, presence: false
  validates :degree, presence: false
  validates :num_jobs_done,
            numericality: { only_integer: true, greater_than_or_equal_to: 0, "error": 'ERR_INVALID',
                            "description": 'Attribute is malformed or unknown' }
  validates :gender,
            inclusion: { in: %w[male female other], "error": 'ERR_INVALID', "description": 'Attribute is invalid' }, presence: false
  validates :spontaneity, presence: false,
                          numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100, "error": 'ERR_INVALID', "description": 'Attribute is malformed or unknown' }
  validates :job_types, presence: false
  validates :key_skills, presence: false
  validates :salary_range, presence: false
  validate :salary_range_validation

  attribute :job_types, :json
  attribute :salary_range, :float, array: true
  attribute :num_jobs_done, :integer

  private

  def salary_range_validation
    return unless salary_range_valid?

    return unless salary_range[1] < salary_range[0]

    errors.add(:salary_range,
               { "error": 'ERR_INVALID',
                 "description": 'Lower bound must be smaller or equal than upper bound' })
  end

  def salary_range_valid?
    salary_range.present? && salary_range.size == 2 && salary_range[1].present? && salary_range[0].present?
  end
end
