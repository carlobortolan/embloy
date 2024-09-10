# frozen_string_literal: true

# Reference: https://developers.ashbyhq.com/docs/setting-up-webhooks
module Integrations
  # AshbyWebhooksController handles all webhook-related actions for Ashby
  class AshbyWebhooksController < IntegrationsController
    ASHBY_WEBHOOK_URL = 'https://api.ashbyhq.com/webhook'

    # def self.refresh_webhooks(client)
    #   response = Integrations::AshbyController.make_request("#{ASHBY_WEBHOOK_URL}.get", client)
    #   Rails.logger.debug("Response from Ashby API: #{response.body}")
    #   case response
    #   when Net::HTTPSuccess
    #     if JSON.parse(response.body)['success'] == true
    #       JSON.parse(response.body)['results']
    #     else
    #       Rails.logger.error("Failed to fetch webhooks: #{response.body}")
    #       []
    #     end
    #     manage_webhooks([], client)
    #   when Net::HTTPBadRequest
    #     raise CustomExceptions::InvalidInput::Quicklink::Request::Malformed
    #   when Net::HTTPUnauthorized
    #     raise CustomExceptions::InvalidInput::Quicklink::ApiKey::Unauthorized
    #   when Net::HTTPForbidden
    #     raise CustomExceptions::InvalidInput::Quicklink::ApiKey::Forbidden
    #   when Net::HTTPNotFound
    #     raise CustomExceptions::InvalidInput::Quicklink::Request::NotFound
    #   end
    # end

    def self.refresh_webhooks(client) # rubocop:disable Metrics/AbcSize
      existing_webhooks = client.webhooks.where(source: 'ashby') || []
      existing_webhook_events = existing_webhooks.map(&:event)

      message = "Found #{existing_webhooks.length} existing webhooks...\n"

      # Delete webhooks that are not in the desired list
      existing_webhooks.each do |webhook|
        message += delete_webhook(webhook.ext_id.split('__').last, client) unless ASHBY_WEBHOOKS.any? do |dw|
          dw[:webhookType] == webhook.event && "#{dw[:requestUrl]}/#{SimpleCrypt.encrypt(client.id.to_i)}" == webhook.url
        end
      end

      # Create or update webhooks
      ASHBY_WEBHOOKS.each do |desired_webhook|
        desired_webhook[:requestUrl] += "/#{SimpleCrypt.encrypt(client.id.to_i)}"
        if existing_webhook_events.include?(desired_webhook[:webhookType])
          message += update_webhook(desired_webhook, client)
        else
          message += "Missing webhook for event '#{desired_webhook[:webhookType]}':\n"
          message += create_webhook(desired_webhook, client)
        end
      end

      message
    end

    # Reference: https://developers.ashbyhq.com/reference/webhookcreate
    def self.create_webhook(webhook, client)
      message = "\tCreating webhook for event '#{webhook[:webhookType]}..."
      response = AshbyController.make_request("#{ASHBY_WEBHOOK_URL}.create", client, 'post', webhook)
      data = JSON.parse(response.body)

      if response.code.to_i == 200 && data['success'] == true
        client.webhooks.create!(ext_id: "ashby__#{data['results']['id']}", url: data['results']['requestUrl'], event: data['results']['webhookType'], source: 'ashby',
                                signatureToken: data['results']['secretToken'])
        Rails.logger.debug("Webhook for event '#{webhook[:webhookType]}' created successfully.")
        message += "webhook created successfully 🚀\n"
      else
        Rails.logger.error("Failed to create webhook for event '#{webhook[:webhookType]}': #{response.body}")
        message += "failed to create webhook for event '#{webhook[:webhookType]}' 💥\n"
      end

      message
    end

    def self.update_webhook(webhook, client)
      message = "Updating webhook for event '#{webhook[:webhookType]}':\n"
      existing_webhook = client.webhooks.find_by(event: webhook[:webhookType], url: webhook[:requestUrl], source: 'ashby')
      message += delete_webhook(existing_webhook.ext_id.split('__').last, client) if existing_webhook
      message += create_webhook(webhook, client)
      message
    end

    # Reference: https://developers.ashbyhq.com/reference/webhookdelete
    def self.delete_webhook(webhook_id, client)
      message = "\tDeleting webhook with ID '#{webhook_id}'... "
      response = AshbyController.make_request("#{ASHBY_WEBHOOK_URL}.delete", client, 'post', { 'webhookId' => webhook_id })

      if (response.code.to_i == 200 && JSON.parse(response.body)['success'] == true) || JSON.parse(response.body)['errors'] == ['webhook_not_found']
        client.webhooks.find_by(ext_id: "ashby__#{webhook_id}")&.destroy
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
