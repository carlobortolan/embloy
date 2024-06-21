# frozen_string_literal: true

# The ApplicationAnswer class represents a user's answer to an application option.
class ApplicationAnswer < ApplicationRecord
  acts_as_paranoid

  belongs_to :application, foreign_key: %i[user_id job_id], primary_key: %i[user_id job_id]
  belongs_to :application_option
  belongs_to :user
  belongs_to :job

  has_one_attached :attachment, dependent: :destroy

  validates :application_option, presence: true
  validates :answer, presence: { error: 'ERR_BLANK', description: "Attribute can't be blank" },
                     length: { minimum: 0, maximum: 1000, error: 'ERR_LENGTH', description: 'Answer must be no more than 1000 characters' }, if: -> { application_option.question_type != 'file' }
  validate :validate_answer

  VALIDATORS = {
    'short_text' => :validate_text_or_link_answer,
    'link' => :validate_text_or_link_answer,
    'single_choice' => :validate_single_choice_answer,
    'multiple_choice' => :validate_multiple_choice_answer,
    'yes_no' => :validate_yes_no_answer,
    'long_text' => :validate_long_text_answer,
    'date' => :validate_date_answer,
    'location' => :validate_location_answer,
    'number' => :validate_number_answer,
    'file' => :validate_file_answer
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

  def validate_date_answer
    begin
      return if Date.parse(answer)
    rescue StandardError
      false
    end

    errors.add(:answer, 'Invalid date answer')
  end

  def validate_single_choice_answer
    errors.add(:answer, 'Invalid or missing choice answer') and return if answer.blank?
    return if application_option.options.include?(answer)

    errors.add(:answer, 'Answer must be one of the provided options for single_choice')
  end

  def validate_multiple_choice_answer
    errors.add(:answer, 'Invalid or missing choice answer') and return if answer.blank?

    answer_array = answer.is_a?(String) ? JSON.parse(answer) : answer
    return if answer_array.is_a?(Array) && (answer_array - application_option.options).empty?

    errors.add(:answer, 'All answers must be in the provided options for multiple_choice')
  end

  def validate_file_answer # rubocop:disable Metrics/AbcSize
    return unless attachment.attached?

    if attachment.blob.byte_size > 2.megabytes
      attachment.purge
      errors.add(:attachment, 'is too large (max is 2 MB)')
      return
    end

    allowed_file_types = (application_option.options.presence & ApplicationOption::ALLOWED_FILE_TYPES) || ['pdf']
    return if allowed_file_types.include?(attachment.blob.content_type.split('/').last)

    attachment.purge
    errors.add(:attachment, "File type is not allowed. Allowed types: #{allowed_file_types.join(', ')}")
  end
end
