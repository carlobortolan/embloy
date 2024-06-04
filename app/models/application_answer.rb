# frozen_string_literal: true

# The ApplicationAnswer class represents a user's answer to an application option.
class ApplicationAnswer < ApplicationRecord
  acts_as_paranoid

  belongs_to :application, foreign_key: %i[user_id job_id], primary_key: %i[user_id job_id]
  belongs_to :application_option
  belongs_to :user
  belongs_to :job

  validates :application_option, presence: true
  validates :answer, presence: { error: 'ERR_BLANK', description: "Attribute can't be blank" },
                     length: { minimum: 0, maximum: 1000, error: 'ERR_LENGTH', description: 'Answer must be no more than 1000 characters' }
  validate :answer_validation # TODO: DEPRECATED
  validate :validate_answer

  VALIDATORS = {
    'short_text' => :validate_text_or_link_answer,
    'link' => :validate_text_or_link_answer,
    'single_choice' => :validate_choice_answer,
    'multiple_choice' => :validate_choice_answer,
    'yes_no' => :validate_yes_no_answer,
    'long_text' => :validate_long_text_answer,
    'date' => :validate_date_answer,
    'location' => :validate_location_answer,
    'number' => :validate_number_answer
  }.freeze

  private

  def validate_answer
    return unless application_option

    method = VALIDATORS[application_option.question_type]
    send(method) if method
  end

  def validate_text_or_link_answer
    return unless (answer.blank? && application_option.required) || answer.length > 200

    errors.add(:answer, 'Invalid or missing text/link answer')
  end

  def validate_long_text_answer
    return unless (answer.blank? && application_option.required) || answer.length > 1000

    errors.add(:answer, 'Invalid or missing long text answer')
  end

  def validate_location_answer
    # TODO: location is currently stored as a string - maybe update in the future
    return unless (answer.blank? && application_option.required) || answer.length > 1000

    errors.add(:answer, 'Invalid or missing location answer')
  end

  def validate_number_answer
    return if answer =~ /\A-?\d+(\.\d+)?\z/

    errors.add(:answer, 'Invalid number answer')
  end

  def validate_yes_no_answer
    return if %w[yes no].include?(answer.downcase)

    errors.add(:answer, 'Invalid yes/no answer')
  end

  def validate_choice_answer
    return unless answer.blank?

    errors.add(:answer, 'Invalid or missing choice answer')
  end

  def validate_date_answer
    begin
      return if Date.parse(answer)
    rescue StandardError
      false
    end

    errors.add(:answer, 'Invalid date answer')
  end

  # TODO: DEPRECATED
  def answer_validation
    return unless application_option.required || answer.present?

    validate_single_choice_answer if application_option.question_type == 'single_choice'
    validate_multiple_choice_answer if application_option.question_type == 'multiple_choice'
  end

  # TODO: DEPRECATED
  def validate_single_choice_answer
    return if application_option.options.include?(answer)

    errors.add(:answer, 'Answer must be one of the provided options for single_choice')
  end

  # TODO: DEPRECATED
  def validate_multiple_choice_answer
    answer_array = answer.is_a?(String) ? JSON.parse(answer) : answer
    return if answer_array.is_a?(Array) && (answer_array - application_option.options).empty?

    errors.add(:answer, 'All answers must be in the provided options for multiple_choice')
  end
end
