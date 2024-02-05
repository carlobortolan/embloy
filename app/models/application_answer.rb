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
                     length: { minimum: 0, maximum: 500, error: 'ERR_LENGTH', description: 'Answer must be no more than 500 characters' }
  validate :answer_validation
  validate :validate_answer

  private

  def answer_validation
    return unless application_option.required || answer.present?

    validate_single_choice_answer if application_option.question_type == 'single_choice'
    validate_multiple_choice_answer if application_option.question_type == 'multiple_choice'
  end

  def validate_single_choice_answer
    return if application_option.options.include?(answer)

    errors.add(:answer, 'Answer must be one of the provided options for single_choice')
  end

  def validate_multiple_choice_answer
    answer_array = answer.is_a?(String) ? JSON.parse(answer) : answer
    return if answer_array.is_a?(Array) && (answer_array - application_option.options).empty?

    errors.add(:answer, 'All answers must be in the provided options for multiple_choice')
  end

  def validate_answer
    return unless application_option

    validate_text_or_link_answer if %w[text link].include?(application_option.question_type)
    validate_choice_answer if %w[single_choice multiple_choice].include?(application_option.question_type)
    validate_yes_no_answer if application_option.question_type == 'yes_no'
  end

  def validate_text_or_link_answer
    return unless (answer.blank? && application_option.required) || answer.length > 500

    errors.add(:answer, 'Invalid or missing text/link answer')
  end

  def validate_choice_answer
    return unless answer.blank?

    errors.add(:answer, 'Invalid or missing choice answer')
  end

  def validate_yes_no_answer
    return if %w[yes no].include?(answer.downcase)

    errors.add(:answer, 'Invalid yes/no answer')
  end
end
