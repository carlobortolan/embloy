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

    # Handles incoming webhooks from Lever and saves them as application events to the database
    def lever # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
      # Parse the incoming webhook payload
      lever_event = JSON.parse(request.body.read)

      webhook = Webhook.find_by(source: 'lever', event: lever_event['event'], user_id: SimpleCrypt.decrypt(params[:id] || ''))
      render json: { error: 'Webhook not found' }, status: :not_found and return if webhook.nil?

      # Verify the webhook signature
      unless Integrations::Lever::WebhooksController.verify_signature(
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

        application.accept 'Accepted'
      when 'candidateDeleted'
        application = Application.find_by(ext_id:)
        render json: { error: 'Application not found' }, status: :not_found and return unless application

        application.reject 'Rejected'
      when 'candidateStageChange', 'candidateArchiveChange', 'interviewCreated', 'interviewUpdated', 'interviewDeleted'
        application = Application.find_by(ext_id:)

        application.update!(status: :pending, response: 'No response yet ...') and return if lever_event['data']['toArchived'].nil?
        application.accept 'Accepted' and return if lever_event['data']['toStageId'] == 'offer'
        application.reject 'Rejected' and return if lever_event['data']['toArchived'].present? && !application.accepted?
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

    # Handles incoming webhooks from Lever and updates the job, or saves them as application events to the database
    def ashby # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
      ashby_event = JSON.parse(request.body.read)

      # Handle ping event
      render json: { message: 'Ping received' }, status: :ok and return if ashby_event['action'] == 'ping'

      webhook = Webhook.find_by(source: 'ashby', event: ashby_event['action'], user_id: SimpleCrypt.decrypt(params[:id] || ''))

      Rails.logger.debug("Webhook: #{webhook}")
      Rails.logger.debug("user_id: #{SimpleCrypt.decrypt(params[:id] || '')}")
      Rails.logger.debug("event: #{ashby_event['action']}")

      render json: { error: 'Webhook not found' }, status: :not_found and return if webhook.nil?

      # Verify the webhook signature
      unless Integrations::Ashby::WebhooksController.verify_signature(
        request.body.read,
        request.headers['Ashby-Signature'],
        webhook.signatureToken
      )
        render json: { error: 'Invalid signature' }, status: :unauthorized and return
      end

      app_ext_id = "ashby__#{ashby_event.dig('data', 'application', 'id')}"
      job_ext_id = "ashby__#{ashby_event.dig('data', 'jobPosting', 'id')}"
      # int_ext_id = "ashby__#{ashby_event['data']['interviewSchedule']['id']}"

      application = Application.find_by(ext_id: app_ext_id) if app_ext_id
      job = Job.find_by(job_slug: job_ext_id, user_id: webhook.user_id) if job_ext_id
      # interview = Interview.find_by(ext_id: int_ext_id) if int_ext_id

      case ashby_event['action']
      when 'applicationSubmit'

        render json: { error: 'Application not found' }, status: :not_found and return unless application
      when 'candidateHire'
        render json: { error: 'Application not found' }, status: :not_found and return unless application

        application.accept 'Accepted'
      when 'candidateStageChange', 'applicationUpdate'
        render json: { error: 'Application not found' }, status: :not_found and return unless application

        case ashby_event['data']['application']['status']
        when 'Archived'
          application.reject 'Rejected'
        when 'Hired'
          application.accept 'Accepted'
        else # 'Active', 'Lead'
          application.update!(status: :pending, response: 'No response yet ...')
        end
      when 'jobCreate', 'jobUpdate'
        # TODO: Update embloy job for each ashby_event[:data][:job][:jobPostingIds]
        return
      when 'jobPostingUpdate'
        render json: { error: 'Job not found' }, status: :not_found and return if job.nil?

        Integrations::Ashby::AshbyController.fetch_posting(job_ext_id.split('__').last, webhook.user, job)
        return
      when 'jobPostingPublish'
        render json: { error: 'Job not found' }, status: :not_found and return if job.nil?

        job.update!(job_status: 'listed')
        render json: { message: 'Posting Updated' }, status: :ok and return
      when 'jobPostingUnpublish'
        render json: { error: 'Job not found' }, status: :not_found and return if job.nil?

        job.update!(job_status: 'unlisted')
        render json: { message: 'Posting Updated' }, status: :ok and return
      when 'jobPostingDelete'
        render json: { error: 'Job not found' }, status: :not_found and return if job.nil?

        job.update!(job_status: 'archived')
        render json: { message: 'Posting Updated' }, status: :ok and return
      when 'interviewScheduleCreate', 'interviewScheduleUpdate'
        # TODO: Implement embloy interview models first
        # interview = Interview.find_by(ext_id: int_ext_id)
        # render json: { error: 'Interview not found' }, status: :not_found and return if interview.nil?
        #
        # interview.create_or_update!(
        #   ext_id: int_ext_id,
        #   application_id: application.id,
        #   job_id: job.id,
        #   user_id: application.user_id,
        #   internal_status: ashby_event['data']['interviewSchedule']['status'],
        #   interview_stage: ashby_event['data']['interviewSchedule']['interviewStageId'],
        #   interview_events: ashby_event['data']['interviewSchedule']['interviewEvents']
        # )
      when 'interviewPlanTransition', 'candidateDelete', 'candidateMerge', 'offerCreate', 'offerDelete', 'offerUpdate', 'openingCreate', 'pushToHRIS', 'surveySubmit'
      # TODO: Do nothing
      else
        render json: { error: 'Unknown event type' }, status: :unprocessable_entity and return
      end

      render json: { error: 'Application not found' }, status: :not_found and return if application.nil?

      process_ashby_event(application, ashby_event)
      render json: { message: 'Event processed' }, status: :ok
    end

    private

    def process_ashby_event(application, ashby_event)
      ApplicationEvent.create!(
        ext_id: application.ext_id,
        job_id: application.job_id,
        user_id: application.user_id,
        event_type: ashby_event['action'],
        event_details: ashby_event['data'].to_json,
        previous_event_id: application.application_events.last&.id
      )
    end
  end
end
