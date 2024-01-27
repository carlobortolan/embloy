# frozen_string_literal: true

# The ApplicationBuilder is responsible for handling the application creation process.
module ApplicationBuilder
  extend ActiveSupport::Concern

  # The apply_for_job method is responsible for creating a new application for a job.
  # Requires @job and application_params
  # rubocop:disable Metrics/AbcSize
  def apply_for_job
    puts 'START 1'
    ActiveRecord::Base.transaction do
      create_application!
      puts 'EXEC 2'
      create_application_answers! if @job.application_options.any?
      puts 'EXEC 3'

      if @job.cv_required
        puts 'EXEC 4'
        if application_params[:application_attachment].nil?
          @application.errors.add(:application_attachment, 'CV is required')
          render json: { errors: @application.errors }, status: :unprocessable_entity and return
        end

        puts 'EXEC 5'
        attachment_format = application_params[:application_attachment].content_type
        allowed_formats = ApplicationHelper.allowed_cv_formats_for_form(@job.allowed_cv_formats)

        unless allowed_formats.include?(attachment_format)
          puts 'EXEC 6'
          @application.errors.add(:application_attachment, 'Invalid CV format')
          render json: { errors: @application.errors }, status: :unprocessable_entity and return
        end

        puts 'EXEC 7'
        create_application_attachment!
        puts 'EXEC 8'
      end
    end
    render status: 201, json: { message: 'Application submitted!' }
  rescue ActiveRecord::RecordInvalid => e
    render status: 400, json: { errors: e.record.errors.details }
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    malformed_error('image_url')
  rescue ActiveRecord::RecordNotUnique
    unnecessary_error('application')
  end
  # rubocop:enable Metrics/AbcSize

  private

  # Creates @application
  def create_application!
    puts 'EXEC 1.1'
    tmp = application_params.except(:id, :application_attachment, :application_answers)
    tmp[:job_id] =  @job.id
    tmp[:user_id] = Current.user.id
    @application = Application.new(tmp)
    puts 'EXEC 1.2'
    @application.save!
  end

  def create_application_answers!
    if application_params[:application_answers]
      application_params[:application_answers].each_value do |answer|
        application_option = ApplicationOption.find(answer[:application_option_id].to_i)
        answer_array = answer[:answer].split(', ').map(&:strip) if application_option.question_type == 'multiple_choice'
        answer_array ||= answer[:answer]
        if application_option
          ApplicationAnswer.create!(
            job_id: @job.id.to_i,
            user_id: Current.user.id.to_i,
            application_option:,
            answer: answer_array
          )
        else
          @application.errors.add(:application_answers, 'Invalid application option')
        end
      end
    else
      @application.errors.add(:application_answers, 'Application answer missing')
    end
  end

  def awdawcreate_application_answers!
    application_params[:application_answers].each_value do |answer|
      application_option = ApplicationOption.find(answer[:application_option_id].to_i)
      ApplicationAnswer.create!(
        job_id: @job.id.to_i,
        user_id: Current.user.id.to_i,
        application_option:,
        answer: answer[:answer]
      )
    end
  end

  def create_application_attachment!
    application_attachment = ApplicationAttachment.create!(
      user_id: Current.user.id,
      job_id: @job.id
    )
    application_attachment.save!
    application_attachment.cv.attach(application_params[:application_attachment])
  end
end
