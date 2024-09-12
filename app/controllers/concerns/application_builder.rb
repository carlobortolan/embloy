# frozen_string_literal: true

# The ApplicationBuilder is responsible for handling the application creation process.
module ApplicationBuilder
  extend ActiveSupport::Concern

  # The apply_for_job method is responsible for creating a new application for a job.
  # Requires @job and application_params
  def apply_for_job
    ActiveRecord::Base.transaction do
      create_application!
    end
    render status: 201, json: { message: 'Application submitted!' }
  rescue ActiveRecord::RecordInvalid => e
    render status: 400, json: { errors: e.record.errors.details }
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    malformed_error('image_url')
  rescue ActiveRecord::RecordNotUnique => e
    unnecessary_error('application', 'You have already applied for this job. Please note that you can only apply once.') unless Current.user.admin?
    retry if Current.user.admin?
  rescue StandardError => e
    render status: 500, json: { errors: e.message }
  end

  private

  # Creates @application
  def create_application!
    tmp = application_params.except(:id, :application_answers)
    tmp[:job_id] = @job.id
    tmp[:user_id] = Current.user.id
    @application = Application.new(tmp)

    begin
      @application.save!
    rescue ActiveRecord::RecordNotUnique
      raise ActiveRecord::RecordNotUnique, 'You have already applied for this job. Please note that you can only apply once.' unless Current.user.admin?

      # If the user is an admin, find and destroy the existing application, then save the new one
      existing_application = Application.find_by(job_id: @job.id, user_id: Current.user.id)
      existing_application&.destroy!
      @application.save!
    end

    create_application_answers! if @job.application_options.any?
    Integrations::IntegrationsController.submit_form(@job.job_slug, @application, application_params, @client)
  end

  # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
  def create_application_answers!
    @job.application_options.each do |option|
      answer_params = find_answer_params(option.id)

      if option.required && (answer_params.nil? || (answer_params.last[:answer].blank? && option.question_type != 'file'))
        @application.errors.add(:application_answers, "Answer for required option #{option.id} is missing")
        raise ActiveRecord::RecordInvalid, @application
      end

      if !answer_params&.last&.[](:answer).blank? || (option.question_type == 'file' && !answer_params&.last&.[](:file).blank?)

        if option.question_type != 'multiple_choice' && option.question_type != 'file' && !answer_params.last[:answer].is_a?(String)
          @application.errors.add(:base, 'Invalid answer type')
          raise ActiveRecord::RecordInvalid, @application
        end

        process_answer(option, answer_params)

      elsif option.required
        @application.errors.add(:base, "Invalid application answer parameters for option #{option.id}")
        raise ActiveRecord::RecordInvalid, @application
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

  def process_answer(option, answer_params)
    answer_array = if option.question_type == 'multiple_choice' && answer_params.last[:answer]
                     answer_params.last[:answer].strip.split('||| ').reject(&:empty?).map(&:strip)
                   else
                     answer_params.last[:answer]
                   end

    application_answer = ApplicationAnswer.create!(job_id: @job.id.to_i, user_id: Current.user.id.to_i, application_option: option, answer: answer_array)
    application_answer.attachment.attach(answer_params.last[:file]) if answer_params.last[:file]
  end
  # rubocop:enable Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
end
