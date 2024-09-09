# frozen_string_literal: true

# Reference: https://hire.sandbox.lever.co/developer/documentation#webhooks
module Integrations
  # LeverWebhooksController handles all webhook-related actions for Lever
  class LeverWebhooksController < IntegrationsController
    LEVER_WEBHOOK_URL = 'https://api.sandbox.lever.co/v1/webhooks'

    def self.refresh_webhooks(client)
      response = Integrations::LeverController.fetch_from_lever(LEVER_WEBHOOK_URL, client)
      Rails.logger.debug("Response from Lever API: #{response.body}")
      case response
      when Net::HTTPSuccess || Net::HTTPNoContent
        existing_webhooks = JSON.parse(response.body)['data']
        manage_webhooks(existing_webhooks, client)
      when Net::HTTPBadRequest
        raise CustomExceptions::InvalidInput::Quicklink::Request::Malformed
      when Net::HTTPUnauthorized
        raise CustomExceptions::InvalidInput::Quicklink::OAuth::Unauthorized
      when Net::HTTPForbidden
        raise CustomExceptions::InvalidInput::Quicklink::OAuth::Forbidden
      when Net::HTTPNotFound
        raise CustomExceptions::InvalidInput::Quicklink::Request::NotFound
      end
    end

    def self.manage_webhooks(existing_webhooks, client) # rubocop:disable Metrics/PerceivedComplexity,Metrics/AbcSize
      message = "Found #{existing_webhooks.length} existing webhooks...\n"
      if existing_webhooks.nil? || existing_webhooks.empty?
        Rails.logger.debug('No existing webhooks found.')
        existing_webhooks = []
      end

      existing_webhook_events = existing_webhooks.map { |wh| wh['event'] }

      # Delete webhooks that are not in the desired list
      existing_webhooks.each do |webhook|
        delete_webhook(webhook['id'], webhook['event'], client) unless LEVER_WEBHOOKS.any? do |dw|
          dw[:event] == webhook['event'] && "#{dw[:url]}/#{SimpleCrypt.encrypt(client.id.to_i)}" == webhook['url']
        end
      end

      # Create or update webhooks
      LEVER_WEBHOOKS.each do |desired_webhook|
        desired_webhook[:url] += "/#{SimpleCrypt.encrypt(client.id.to_i)}"
        if existing_webhook_events.include?(desired_webhook[:event])
          message += update_webhook(desired_webhook, client)
        else
          message += "Missing webhook for event '#{desired_webhook[:event]}':\n"
          message += create_webhook(desired_webhook, client)
        end
      end

      message
    end

    def self.create_webhook(webhook, client) # rubocop:disable Metrics/AbcSize
      message = "\tCreating webhook for event '#{webhook[:event]}'..."

      uri = URI.parse(LEVER_WEBHOOK_URL)
      request = Net::HTTP::Post.new(uri)
      request['Authorization'] = "Bearer #{LeverController.validate_token(client)}"
      request['Content-Type'] = 'application/json'
      request.body = webhook.to_json

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        http.request(request)
      end

      data = JSON.parse(response.body)

      if response.code.to_i == 201
        client.webhooks.create!(ext_id: "lever__#{data['data']['id']}", url: data['data']['url'], event: data['data']['event'], source: 'lever',
                                signatureToken: data['data']['configuration']['signatureToken'])
        Rails.logger.debug("Webhook for event '#{webhook[:event]}' created successfully.")
        message += "webhook created successfully 🚀\n"
      else
        message += "failed to create webhook for event '#{webhook[:event]}' 💥\n"
        Rails.logger.error("Failed to create webhook for event '#{webhook[:event]}': #{response.body}")
      end

      message
    end

    def self.update_webhook(webhook, client)
      message = "Updating webhook for event '#{webhook[:event]}':\n"
      existing_webhook = client.webhooks.find_by(event: webhook[:event], url: webhook[:url], source: 'lever')
      message += delete_webhook(existing_webhook.ext_id.split('__').last, existing_webhook.event, client) if existing_webhook
      message += create_webhook(webhook, client)
      message
    end

    def self.delete_webhook(webhook_id, event, client)
      message = "\tDeleting webhook for event '#{event}'... "
      uri = URI.parse("#{LEVER_WEBHOOK_URL}/#{webhook_id}")
      request = Net::HTTP::Delete.new(uri)
      request['Authorization'] = "Bearer #{LeverController.validate_token(client)}"

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        http.request(request)
      end

      if response.code.to_i == 204
        client.webhooks.find_by(ext_id: "lever__#{webhook_id}")&.destroy
        Rails.logger.debug("Webhook with ID '#{webhook_id}' deleted successfully.")
        message += "webhook deleted successfully 🚀\n"
      else
        Rails.logger.error("Failed to delete webhook with ID '#{webhook_id}': #{response.body}")
        message += "failed to delete webhook with ID '#{webhook_id}' 💥\n"
      end

      message
    end

    def self.verify_signature(token, triggered_at, signature, signature_token)
      Rails.logger.debug("Starting verification with token: #{token}, triggered_at: #{triggered_at}, signature: #{signature}, signature_token: #{signature_token}")

      # Concatenate token and triggered_at values
      plain_text = token + triggered_at.to_s

      # Encode the resulting string with the HMAC algorithm
      computed_signature = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), signature_token, plain_text)

      Rails.logger.debug("Computed signature: #{computed_signature}")
      Rails.logger.debug("Signature: #{signature}")

      # Compare the resulting hexdigest to the signature
      if ActiveSupport::SecurityUtils.secure_compare(computed_signature, signature)
        # Cache the token to prevent replay attacks
        Rails.logger.debug('Signature verified successfully.')
        true
      else
        Rails.logger.error('Signature verification failed.')
        false
      end
    end
  end
end

LEVER_WEBHOOKS = [
  {
    event: 'applicationCreated',
    url: 'https://api.embloy.com/api/v0/webhooks/lever',
    configuration: {
      conditions: {
        origins: %w[
          applied
          sourced
          referred
          university
          agency
          internal
        ]
      }
    }
  },
  {
    event: 'candidateHired',
    url: 'https://api.embloy.com/api/v0/webhooks/lever',
    configuration: {
      conditions: {
        origins: %w[
          applied
          sourced
          referred
          university
          agency
          internal
        ]
      }
    }
  },
  {
    event: 'candidateStageChange',
    url: 'https://api.embloy.com/api/v0/webhooks/lever',
    configuration: {
      conditions: {
        origins: %w[
          applied
          sourced
          referred
          university
          agency
          internal
        ]
      }
    }
  },
  {
    event: 'candidateArchiveChange',
    url: 'https://api.embloy.com/api/v0/webhooks/lever',
    configuration: {
      conditions: {
        origins: %w[
          applied
          sourced
          referred
          university
          agency
          internal
        ]
      }
    }
  },
  { event: 'candidateDeleted', url: 'https://api.embloy.com/api/v0/webhooks/lever' },
  { event: 'interviewCreated', url: 'https://api.embloy.com/api/v0/webhooks/lever' },
  { event: 'interviewUpdated', url: 'https://api.embloy.com/api/v0/webhooks/lever' },
  { event: 'interviewDeleted', url: 'https://api.embloy.com/api/v0/webhooks/lever' }
].freeze
