# frozen_string_literal: true

# Reference: https://hire.sandbox.lever.co/developer/documentation#webhooks
module Integrations
  # LeverWebhooksController handles all webhook-related actions for Lever
  class LeverWebhooksController < IntegrationsController
    LEVER_WEBHOOK_URL = 'https://api.sandbox.lever.co/v1/webhooks'

    def self.refresh_webhooks(client)
      response = Integrations::LeverController.fetch_from_lever(LEVER_WEBHOOK_URL, client)
      Rails.logger.info("Response from Lever API: #{response.body}")
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

    def self.manage_webhooks(existing_webhooks, client) # rubocop:disable Metrics/PerceivedComplexity
      if existing_webhooks.nil? || existing_webhooks.empty?
        Rails.logger.info('No existing webhooks found.')
        existing_webhooks = []
      end

      existing_webhook_events = existing_webhooks.map { |wh| wh['event'] }

      # Delete webhooks that are not in the desired list
      existing_webhooks.each do |webhook|
        delete_webhook(webhook['id'], client) unless LEVER_WEBHOOKS.any? do |dw|
          dw[:event] == webhook['event'] && "#{dw[:url]}/#{SimpleCrypt.encrypt(client.id.to_i)}" == webhook['url']
        end
      end

      # Create or update webhooks
      LEVER_WEBHOOKS.each do |desired_webhook|
        desired_webhook[:url] += "/#{SimpleCrypt.encrypt(client.id.to_i)}"
        if existing_webhook_events.include?(desired_webhook[:event])
          update_webhook(desired_webhook, client)
        else
          create_webhook(desired_webhook, client)
        end
      end
    end

    def self.create_webhook(webhook, client) # rubocop:disable Metrics/AbcSize
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
        Rails.logger.info("Webhook for event '#{webhook[:event]}' created successfully.")
        client.webhooks.create!(ext_id: "lever__#{data['data']['id']}", url: data['data']['url'], event: data['data']['event'], source: 'lever',
                                signatureToken: data['data']['configuration']['signatureToken'])
      else
        Rails.logger.error("Failed to create webhook for event '#{webhook[:event]}': #{response.body}")
      end
    end

    def self.update_webhook(webhook, client)
      # Assuming Lever API does not support direct update, we delete and recreate
      existing_webhook = client.webhooks.find_by(event: webhook[:event], url: webhook[:url])
      delete_webhook(existing_webhook.ext_id.split('__').last, client) if existing_webhook
      create_webhook(webhook, client)
    end

    def self.delete_webhook(webhook_id, client)
      uri = URI.parse("#{LEVER_WEBHOOK_URL}/#{webhook_id}")
      request = Net::HTTP::Delete.new(uri)
      request['Authorization'] = "Bearer #{LeverController.validate_token(client)}"

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        http.request(request)
      end

      if response.code.to_i == 204
        Rails.logger.info("Webhook with ID '#{webhook_id}' deleted successfully.")
        client.webhooks.find_by(ext_id: "lever__#{webhook_id}")&.destroy
      else
        Rails.logger.error("Failed to delete webhook with ID '#{webhook_id}': #{response.body}")
      end
    end

    def self.verify_signature(token, triggered_at, signature, signature_token)
      puts "Starting verification with token: #{token}, triggered_at: #{triggered_at}, signature: #{signature}, signature_token: #{signature_token}"

      # Concatenate token and triggered_at values
      plain_text = token + triggered_at.to_s

      # Encode the resulting string with the HMAC algorithm
      computed_signature = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), signature_token, plain_text)

      puts "Computed signature: #{computed_signature}"
      puts "Signature: #{signature}"

      # Compare the resulting hexdigest to the signature
      if computed_signature == signature
        # Cache the token to prevent replay attacks
        puts 'Signature verified successfully.'
        true
      else
        puts 'Signature verification failed.'
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
