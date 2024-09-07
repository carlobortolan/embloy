# frozen_string_literal: true

# Path: app/controllers/hooks/webhooks_controller.rb
module Hooks
  # WebhookHandler handles all incoming webhooks from external services
  class WebhooksController < ApplicationController
    include ApiExceptionHandler

    def handle_event
      source = params[:source]
      case source
      when 'lever'
        lever
      when 'ashby'
        ashby
      else
        render json: { error: 'Unknown source' }, status: :unprocessable_entity
      end
    end

    def lever # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
      # Parse the incoming webhook payload
      lever_event = JSON.parse(request.body.read)

      webhook = Webhook.find_by(source: 'lever', event: lever_event['event'], user_id: SimpleCrypt.decrypt(params[:id]))
      render json: { error: 'Webhook not found' }, status: :not_found and return if webhook.nil?

      # Verify the webhook signature
      unless Integrations::LeverWebhooksController.verify_signature(
        lever_event['token'],
        lever_event['triggeredAt'],
        lever_event['signature'],
        webhook.signatureToken
      )
        render json: { error: 'Invalid signature' }, status: :unauthorized and return
      end

      ext_id = "lever__#{lever_event['data']['opportunityId']}"

      case lever_event['event']
      when 'applicationCreated'
        application_id = "lever__#{lever_event['data']['applicationId']}"
        application = Application.find_by(ext_id: application_id)
        render json: { error: 'Application not found' }, status: :not_found and return unless application

        application.update!(ext_id:)
      when 'candidateHired'
        application = Application.find_by(ext_id:)
        render json: { error: 'Application not found' }, status: :not_found and return unless application

        puts 'Hired'
        application.accept 'Accepted'
      when 'candidateDeleted'
        application = Application.find_by(ext_id:)
        render json: { error: 'Application not found' }, status: :not_found and return unless application

        application.reject 'Rejected'
      when 'candidateStageChange', 'candidateArchiveChange', 'interviewCreated', 'interviewUpdated', 'interviewDeleted'
        application = Application.find_by(ext_id:)
        render json: { error: 'Application not found' }, status: :not_found and return if application.nil?
      else
        render json: { error: 'Unknown event type' }, status: :unprocessable_entity and return
      end

      application = Application.find_by(ext_id:)

      render json: { error: 'Application not found' }, status: :not_found and return if application.nil?

      ApplicationEvent.create!(
        ext_id:,
        job_id: application.job_id,
        user_id: application.user_id,
        event_type: lever_event['event'],
        event_details: lever_event['data'].to_json,
        previous_event_id: application.application_events.last&.id
      )
      render json: { message: 'Event processed' }, status: :ok
    end
  end

  private

  def lever_event_params
    params.require(:lever_event).permit(:event, data: {})
  end

  def source_params
    params.require(:source)
  end
end
