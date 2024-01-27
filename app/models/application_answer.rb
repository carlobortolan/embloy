# frozen_string_literal: true

# The ApplicationAnswer class represents a user's answer to an application option.
class ApplicationAnswer < ApplicationRecord
  acts_as_paranoid

  belongs_to :application, foreign_key: %i[user_id job_id], primary_key: %i[user_id job_id]
  belongs_to :application_option
  validates :application_option, presence: true
  validates :answer, presence: { error: 'ERR_BLANK', description: "Attribute can't be blank" }
  validate :answer_validation
  validate :link_validation, if: -> { application_option.question_type == 'link' }
  validate :text_validation, if: -> { application_option.question_type == 'text' }

  private

  def answer_validation
    return unless application_option.options_required?

    puts inspect

    if application_option.question_type == 'single_choice' && !application_option.options.include?(answer)
      errors.add(:answer, 'Answer must be one of the provided options for single_choice')
    elsif application_option.question_type == 'multiple_choice'
      answer_array = answer.is_a?(String) ? JSON.parse(answer) : answer
      errors.add(:answer, 'All answers must be in the provided options for multiple_choice') unless answer_array.is_a?(Array) && (answer_array - application_option.options).empty?
    end
  end

  def link_validation
    uri = URI.parse(answer)
    errors.add(:answer, 'Answer must be a valid URL for link') unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
  rescue URI::InvalidURIError
    errors.add(:answer, 'Answer must be a valid URL for link')
  end

  def text_validation
    return unless answer.length > 500

    errors.add(:answer, 'Answer must be no more than 500 characters for text')
  end
end
