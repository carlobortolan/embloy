# frozen_string_literal: true

# The ApplicationBuilder is responsible for handling the application creation process.
module ApplicationBuilder # rubocop:disable Metrics/ModuleLength
  extend ActiveSupport::Concern

  # The apply_for_job method is responsible for creating a new application for a job.
  # Requires @job and application_params
  def apply_for_job
    Rails.logger.debug "Session: #{@session}"
    ActiveRecord::Base.transaction do
      create_application!
    end
    render status: 201, json: { message: 'Application submitted!' }
  rescue ActiveRecord::RecordInvalid => e
    render status: 400, json: { errors: e.record.errors.details }
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    malformed_error('image_url')
  rescue ActiveRecord::RecordNotUnique
    unnecessary_error('application', 'You have already applied for this job. Please note that you can only apply once.')
  rescue StandardError => e
    render status: 500, json: { errors: e.message }
  end

  private

  # Creates @application
  def create_application! # rubocop:disable Metrics/AbcSize,Metrics/PerceivedComplexity
    tmp = application_params.except(:id, :application_answers, :save_as_draft)
    tmp[:job_id] = @job.id
    tmp[:user_id] = Current.user.id
    tmp[:version] = 1
    save_as_draft = application_params[:save_as_draft] == '1'

    @application = Application.includes(:user, :job).find_by(job_id: @job.id, user_id: Current.user.id)
    Rails.logger.debug "Fetched existing application: #{@application.inspect}"

    if @job.duplicate_application_allowed? && @application.present? && !@application.draft?
      # Save new application with incremented version
      Rails.logger.debug 'Saving new application version as draft'
      @application.update!(version: @application.version + 1, submitted_at: nil)
      create_application_answers!(save_as_draft) if @job.application_options.any?
    elsif @application.present? && @application.draft?
      # Update existing draft application
      Rails.logger.debug 'Updating draft application'
      @application.update!(updated_at: Time.current)
      create_application_answers!(save_as_draft, replace_existing: true) if @job.application_options.any?
    else
      # Create new draft application
      Rails.logger.debug 'Creating new draft application'
      @application = Application.new(tmp)
      @application.save!
      create_application_answers!(save_as_draft) if @job.application_options.any?
    end

    return if save_as_draft

    Rails.logger.debug 'Submitting draft application'
    @application.update!(submitted_at: Time.current)
    Integrations::IntegrationsController.submit_form(@job, @application, application_params, @client, @session)
  end

  def validate_and_build_answers(save_as_draft)
    answers_to_create = []
    attachments_to_attach = []

    @job.application_options.each do |option|
      answer_params = find_answer_params(option.id)
      validate_required_option(option, answer_params, save_as_draft)
      next unless valid_answer?(option, answer_params)

      answer_array = build_answer_array(option, answer_params)
      answer = build_application_answer(option, answer_array)

      option.question_type == 'file' ? validate_attachment(option, answer_params.last[:file]) : validate_answer(answer, option)

      answers_to_create << answer.attributes.except('id')
      attachments_to_attach << { file: answer_params.last[:file], option_id: option.id } if answer_params.last[:file]
    end

    [answers_to_create, attachments_to_attach]
  end

  def create_application_answers!(save_as_draft, replace_existing: false)
    answers_to_create, attachments_to_attach = validate_and_build_answers(save_as_draft)
    insert_answers_and_attach_files(answers_to_create, attachments_to_attach, @job, replace_existing)
  end

  def create_or_update_application_answers!(save_as_draft)
    answers_to_create, attachments_to_attach = validate_and_build_answers(save_as_draft)
    insert_answers_and_attach_files(answers_to_create, attachments_to_attach, @job)
  end

  def validate_required_option(option, answer_params, save_as_draft)
    return if !option.required || save_as_draft
    return unless answer_params.nil? || (answer_params.last[:answer].blank? && option.question_type != 'file') || (answer_params.last[:file].blank? && option.question_type == 'file')

    @application.errors.add(:application_answers, "Answer for required option #{option.id} is missing")
    raise ActiveRecord::RecordInvalid, @application
  end

  def valid_answer?(option, answer_params)
    !answer_params&.last&.[](:answer).blank? || (option.question_type == 'file' && !answer_params&.last&.[](:file).blank?)
  end

  def build_answer_array(option, answer_params)
    if option.question_type == 'multiple_choice' && answer_params.last[:answer]
      answer_params.last[:answer].strip.split('||| ').reject(&:empty?).map(&:strip).to_json
    else
      answer_params.last[:answer]
    end
  end

  def build_application_answer(option, answer_array)
    ApplicationAnswer.new(
      job_id: @job.id.to_i,
      user_id: Current.user.id.to_i,
      application_option_id: option.id,
      answer: answer_array,
      version: @application.version,
      created_at: Time.current,
      updated_at: Time.current
    )
  end

  def validate_answer(answer, option)
    return if answer.valid?

    @application.errors.add(:application, "Invalid application answer for option #{option.id}: #{answer.errors.full_messages.join(', ')}")
    raise ActiveRecord::RecordInvalid, @application
  end

  def validate_attachment(option, file)
    Rails.logger.debug "Validating attachment for option #{option.id}"
    return unless file

    # Check file size
    if file.size > 2.megabytes
      @application.errors.add(:application, "Invalid application answer for option #{option.id}: Attachment is too large (max is 2 MB)")
      raise ActiveRecord::RecordInvalid, @application
    end

    # Check allowed file types
    allowed_file_types = (option.options.presence & ApplicationOption::ALLOWED_FILE_TYPES) || ['pdf']
    file_extension = ApplicationOption::MIME_TYPE_MAPPING[file.content_type]
    return if allowed_file_types.include?(file_extension)

    @application.errors.add(:application, "Invalid application answer for option #{option.id}: File type is not allowed. Allowed types: #{allowed_file_types.join(', ')}")
    raise ActiveRecord::RecordInvalid, @application
  end

  def insert_answers_and_attach_files(answers_to_create, attachments_to_attach, job, replace_existing)
    ApplicationAnswer.where(job_id: job.id, user_id: Current.user.id, version: @application.version).delete_all if replace_existing

    ApplicationAnswer.insert_all(answers_to_create) if answers_to_create.any?

    attachments_to_attach.each do |attachment|
      Rails.logger.debug "Attaching file to application answer for option #{attachment[:option_id]} and file: #{attachment[:file].inspect}"
      application_answer = ApplicationAnswer.find_by(application_option_id: attachment[:option_id], user_id: Current.user.id, job_id: job.id, version: @application.version)

      if application_answer
        file = attachment[:file]
        application_answer.attachment.attach(io: file, filename: file.original_filename, content_type: file.content_type)
        # application_answer.save!
      else
        Rails.logger.error "ApplicationAnswer not found for option #{attachment[:option_id]}"
      end
    end
  end

  def find_answer_params(option_id)
    if application_params[:application_answers].is_a?(Array)
      application_params[:application_answers].find { |v| v[:application_option_id] == option_id.to_s }
    else
      application_params[:application_answers]&.to_unsafe_h&.find { |_, v| v[:application_option_id] == option_id.to_s }
    end
  end
end
