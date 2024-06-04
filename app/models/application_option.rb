# frozen_string_literal: true

# The ApplicationOption class is responsible for validating the application options associated with a job.
# It includes validations for the presence and length of the question, the presence and inclusion of the question_type,
# the inclusion of the required field, and the presence, length, and type of the options.
# It also includes custom validations for the presence, count, length, and type of the options if the question_type is 'single_choice' or 'multiple_choice'.
class ApplicationOption < ApplicationRecord
  belongs_to :job
  acts_as_paranoid
  VALID_QUESTION_TYPES = %w[yes_no short_text long_text number link single_choice multiple_choice date location file].freeze
  ALLOWED_FILE_TYPES = %w[pdf doc docx txt rtf odt jpg jpeg png gif bmp tiff tif svg mp4 avi mov wmv flv mkv webm ogg mp3 wav wma aac m4a zip rar tar 7z gz bz2 xls xlsx ods ppt pptx].freeze
  serialize :options, Array
  before_validation :set_default_ext_id, on: %i[create update], if: -> { ext_id.blank? && deleted_at.nil? }
  before_validation :set_default_file_options

  validates :question, presence: { error: 'ERR_BLANK', description: "Attribute can't be blank" },
                       length: { minimum: 0, maximum: 500, error: 'ERR_LENGTH', description: 'Attribute length is invalid' }
  validates :question_type,
            presence: { error: 'ERR_BLANK', description: "Attribute can't be blank" },
            inclusion: { in: VALID_QUESTION_TYPES, error: 'ERR_INVALID', description: 'Attribute is invalid' }
  validates :required, inclusion: { in: [true, false], error: 'ERR_INVALID', description: 'Attribute is invalid' }
  validates :options, presence: { error: 'ERR_BLANK', description: "Attribute can't be blank" }, if: :options_required?
  validates :options, length: { maximum: 50, message: 'cannot have more than 50 options' }, if: :options_required?
  validate :options_length_validation, if: :options_required?
  validate :options_count_validation, if: :options_required?
  validate :options_type_validation
  validate :options_presence_validation, if: :options_required?
  validates :options, length: { minimum: 0, maximum: 100, error: 'ERR_LENGTH', description: 'Attribute length is invalid' }
  validates :ext_id, uniqueness: { scope: :job_id, error: 'ERR_UNIQUE', description: 'Should be unique per job' }, on: %i[create update], if: -> { deleted_at.nil? }
  validate :file_type_validation, if: :file_option?

  validates :ext_id, uniqueness: { scope: :job_id, message: 'Should be unique per job' }, on: %i[create update], if: -> { deleted_at.nil? }

  enum question_type: { yes_no: 'yes_no', short_text: 'short_text', long_text: 'long_text', number: 'number', date: 'date', location: 'location', link: 'link', single_choice: 'single_choice',
                        multiple_choice: 'multiple_choice', file: 'file' }

  def options_required?
    %w[single_choice multiple_choice].include?(question_type)
  end

  private

  def options_presence_validation
    return unless options.blank?

    errors.add(:options, 'Options cannot be blank for single_choice or multiple_choice')
  end

  def options_count_validation
    return unless options.size > 50

    job.errors.add(:options, 'At most 50 options can be set')
  end

  def options_length_validation
    return unless options.any? { |option| option.length > 100 }

    job.errors.add(:options, 'Each option can be at most 100 characters long')
  end

  def options_type_validation
    return if options.is_a?(Array)

    job.errors.add(:options, 'Options must be an array')
  end

  def file_option?
    question_type == 'file'
  end

  def set_default_file_options
    self.options = ['pdf'] if options.blank? && question_type == 'file'
  end

  def file_type_validation
    return if options.all? { |option| ALLOWED_FILE_TYPES.include?(option) }

    errors.add(:options, "File types must be one of: #{ALLOWED_FILE_TYPES.join(', ')}")
  end

  def set_default_ext_id
    self.ext_id = "embloy__#{SecureRandom.uuid}"
  end
end
