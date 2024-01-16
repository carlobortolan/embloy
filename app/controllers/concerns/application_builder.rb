# frozen_string_literal: true

# The ApplicationBuilder is responsible for handling the application creation process.
module ApplicationBuilder
  extend ActiveSupport::Concern

  # The apply_for_job method is responsible for creating a new application for a job.
  # Requires @job and application_params
  # rubocop:disable Metrics/AbcSize
  def apply_for_job
    ActiveRecord::Base.transaction do
      create_application!
      if @job.cv_required
        if application_params[:application_attachment].nil?
          @application.errors.add(:application_attachment, 'CV is required')
          render json: { errors: @application.errors }, status: :unprocessable_entity and return
        end

        attachment_format = application_params[:application_attachment].content_type
        allowed_formats = ApplicationHelper.allowed_cv_formats_for_form(@job.allowed_cv_formats)

        unless allowed_formats.include?(attachment_format)
          @application.errors.add(:application_attachment, 'Invalid CV format')
          render json: { errors: @application.errors }, status: :unprocessable_entity and return
        end

        create_application_attachment!
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
    tmp = application_params.except(:id, :application_attachment)
    tmp[:job_id] =  @job.id
    tmp[:user_id] = Current.user.id
    @application = Application.new(tmp)
    @application.save!
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
