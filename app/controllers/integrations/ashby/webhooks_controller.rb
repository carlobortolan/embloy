# frozen_string_literal: true

module Integrations
  module Ashby
    # WebhooksController is responsible for handling Ashby webhooks
    class WebhooksController < IntegrationsController
      ASHBY_WEBHOOK_URL = 'https://api.ashbyhq.com/webhook'

      def self.refresh_webhooks(client, delete_all: false) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
        existing_webhooks = client.webhooks.where(source: 'ashby').to_a || []

        message = "Found #{existing_webhooks.length} existing webhooks...\n"

        # Prepare webhooks for deletion (those that are not in the desired list)
        webhooks_to_delete = existing_webhooks

        # Call Ashby API to delete webhooks remotely
        if webhooks_to_delete.any?
          webhooks_to_delete.each do |webhook|
            message += delete_webhook(webhook.ext_id&.split('__')&.last, client) # Remote API delete
          end

          # Batch delete webhooks locally
          client.webhooks.where(ext_id: webhooks_to_delete.map(&:ext_id)).delete_all
          message += "Deleted #{webhooks_to_delete.size} webhooks successfully 🚀\n"
        end

        return if delete_all

        # Prepare webhooks for upsert (create or update)
        webhooks_to_upsert = ASHBY_WEBHOOKS.map do |desired_webhook|
          webhook_copy = desired_webhook.dup
          webhook_copy[:requestUrl] += "/#{SimpleCrypt.encrypt(client.id.to_i)}"

          {
            ext_id: nil, # Placeholder for ext_id to be filled after API response
            url: webhook_copy[:requestUrl],
            event: webhook_copy[:webhookType],
            source: 'ashby',
            signatureToken: desired_webhook[:secretToken],
            created_at: Time.now,
            updated_at: Time.now
          }
        end

        # Call Ashby API to create/update webhooks remotely and collect ext_ids
        webhooks_to_upsert.each do |webhook_data|
          response_message, ext_id = create_webhook(webhook_data, client) # Remote API call to create webhooks
          webhook_data[:ext_id] = ext_id if ext_id
          message += response_message
        end

        # Batch upsert webhooks locally (insert or update)
        if webhooks_to_upsert.any?
          client.webhooks.upsert_all(webhooks_to_upsert, unique_by: [:ext_id])
          message += "Upserted #{webhooks_to_upsert.size} webhooks successfully 🚀\n"
        end

        message
      end

      # Reference: https://developers.ashbyhq.com/reference/webhookcreate
      def self.create_webhook(webhook, client) # rubocop:disable Metrics/AbcSize
        message = "\tCreating webhook for event '#{webhook[:event]}'..."

        # Map Rails Webhook model to Remote API Webhook model
        remote_webhook = {
          webhookType: webhook[:event],
          requestUrl: webhook[:url],
          secretToken: webhook[:signatureToken]
        }

        response = AshbyController.make_request("#{ASHBY_WEBHOOK_URL}.create", client, 'post', remote_webhook)
        ext_id = nil
        if response.code.to_i == 200
          begin
            data = JSON.parse(response.body)
            if data['success'] == true
              ext_id = "ashby__#{data['results']['id']}"
              Rails.logger.debug("Webhook for event '#{webhook[:event]}' created successfully.")
              message += "webhook created successfully 🚀\n"
            else
              Rails.logger.error("Failed to create webhook for event '#{webhook[:event]}': #{response.body}")
              message += "failed to create webhook for event '#{webhook[:event]}' 💥\n"
            end
          rescue JSON::ParserError => e
            Rails.logger.error("Failed to parse JSON response for event '#{webhook[:event]}': #{e.message}")
            message += "failed to create webhook for event '#{webhook[:event]}' due to JSON parsing error 💥\n"
          end
        else
          Rails.logger.error("Failed to create webhook for event '#{webhook[:event]}': #{response.body}")
          message += "failed to create webhook for event '#{webhook[:event]}' 💥\n"
        end

        [message, ext_id]
      end

      # Reference: https://developers.ashbyhq.com/reference/webhookdelete
      def self.delete_webhook(webhook_id, client)
        message = "\tDeleting webhook with ID '#{webhook_id}'... "
        response = AshbyController.make_request("#{ASHBY_WEBHOOK_URL}.delete", client, 'post', { 'webhookId' => webhook_id })

        if (response.code.to_i == 200 && JSON.parse(response.body)['success'] == true) || JSON.parse(response.body)['errors'] == ['webhook_not_found']
          Rails.logger.debug("Webhook with ID '#{webhook_id}' deleted successfully.")
          message += "webhook deleted successfully 🚀\n"
        else
          Rails.logger.error("Failed to delete webhook with ID '#{webhook_id}': #{response.body}")
          message += "failed to delete webhook with ID '#{webhook_id}' 💥\n"
        end

        message
      end

      # Reference: https://developers.ashbyhq.com/docs/authenticating-webhooks
      def self.verify_signature(raw_payload, signature_from_header, secret)
        Rails.logger.debug("Starting verification with raw_payload: #{raw_payload}, signature_from_header: #{signature_from_header}, secret: #{secret}")

        # Compute the HMAC digest
        digest = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), secret, raw_payload)
        computed_signature = "sha256=#{digest}"

        Rails.logger.debug("Computed signature: #{computed_signature}")
        Rails.logger.debug("Signature from header: #{signature_from_header}")

        # Compare the resulting hexdigest to the signature
        if computed_signature && signature_from_header && ActiveSupport::SecurityUtils.secure_compare(computed_signature, signature_from_header)
          Rails.logger.debug('Signature verified successfully.')
          true
        else
          Rails.logger.error('Signature verification failed.')
          false
        end
      end
    end
  end
end

ASHBY_WEBHOOKS = [
  { webhookType: 'applicationSubmit', requestUrl: 'https://api.embloy.com/api/v0/webhooks/ashby', secretToken: ENV.fetch('ASHBY_WEBHOOK_SECRET', nil) },
  { webhookType: 'applicationUpdate', requestUrl: 'https://api.embloy.com/api/v0/webhooks/ashby', secretToken: ENV.fetch('ASHBY_WEBHOOK_SECRET', nil) },
  { webhookType: 'candidateHire', requestUrl: 'https://api.embloy.com/api/v0/webhooks/ashby', secretToken: ENV.fetch('ASHBY_WEBHOOK_SECRET', nil) },
  { webhookType: 'candidateStageChange', requestUrl: 'https://api.embloy.com/api/v0/webhooks/ashby', secretToken: ENV.fetch('ASHBY_WEBHOOK_SECRET', nil) },
  { webhookType: 'candidateDelete', requestUrl: 'https://api.embloy.com/api/v0/webhooks/ashby', secretToken: ENV.fetch('ASHBY_WEBHOOK_SECRET', nil) },
  { webhookType: 'candidateMerge', requestUrl: 'https://api.embloy.com/api/v0/webhooks/ashby', secretToken: ENV.fetch('ASHBY_WEBHOOK_SECRET', nil) },
  { webhookType: 'interviewPlanTransition', requestUrl: 'https://api.embloy.com/api/v0/webhooks/ashby', secretToken: ENV.fetch('ASHBY_WEBHOOK_SECRET', nil) },
  { webhookType: 'interviewScheduleCreate', requestUrl: 'https://api.embloy.com/api/v0/webhooks/ashby', secretToken: ENV.fetch('ASHBY_WEBHOOK_SECRET', nil) },
  { webhookType: 'interviewScheduleUpdate', requestUrl: 'https://api.embloy.com/api/v0/webhooks/ashby', secretToken: ENV.fetch('ASHBY_WEBHOOK_SECRET', nil) },
  { webhookType: 'jobCreate', requestUrl: 'https://api.embloy.com/api/v0/webhooks/ashby', secretToken: ENV.fetch('ASHBY_WEBHOOK_SECRET', nil) },
  { webhookType: 'jobUpdate', requestUrl: 'https://api.embloy.com/api/v0/webhooks/ashby', secretToken: ENV.fetch('ASHBY_WEBHOOK_SECRET', nil) },
  { webhookType: 'jobPostingUpdate', requestUrl: 'https://api.embloy.com/api/v0/webhooks/ashby', secretToken: ENV.fetch('ASHBY_WEBHOOK_SECRET', nil) },
  { webhookType: 'jobPostingDelete', requestUrl: 'https://api.embloy.com/api/v0/webhooks/ashby', secretToken: ENV.fetch('ASHBY_WEBHOOK_SECRET', nil) },
  { webhookType: 'jobPostingUnpublish', requestUrl: 'https://api.embloy.com/api/v0/webhooks/ashby', secretToken: ENV.fetch('ASHBY_WEBHOOK_SECRET', nil) },
  { webhookType: 'jobPostingPublish', requestUrl: 'https://api.embloy.com/api/v0/webhooks/ashby', secretToken: ENV.fetch('ASHBY_WEBHOOK_SECRET', nil) },
  { webhookType: 'offerCreate', requestUrl: 'https://api.embloy.com/api/v0/webhooks/ashby', secretToken: ENV.fetch('ASHBY_WEBHOOK_SECRET', nil) },
  { webhookType: 'offerUpdate', requestUrl: 'https://api.embloy.com/api/v0/webhooks/ashby', secretToken: ENV.fetch('ASHBY_WEBHOOK_SECRET', nil) },
  { webhookType: 'offerDelete', requestUrl: 'https://api.embloy.com/api/v0/webhooks/ashby', secretToken: ENV.fetch('ASHBY_WEBHOOK_SECRET', nil) },
  { webhookType: 'pushToHRIS', requestUrl: 'https://api.embloy.com/api/v0/webhooks/ashby', secretToken: ENV.fetch('ASHBY_WEBHOOK_SECRET', nil) },
  { webhookType: 'surveySubmit', requestUrl: 'https://api.embloy.com/api/v0/webhooks/ashby', secretToken: ENV.fetch('ASHBY_WEBHOOK_SECRET', nil) }
].freeze
