# frozen_string_literal: true

# SubscriptionStatus module provides methods for checking and updating
# the status of a user's subscription.
module SubscriptionStatus
  extend ActiveSupport::Concern

  included do # rubocop:disable Metrics/BlockLength
    def current_subscription_info
      sync_subscriptions
      subscription = payment_processor&.subscription
      subscription&.processor_subscription if valid_subscription?(subscription)
    end

    def current_subscription
      sync_subscriptions
      subscription = payment_processor&.subscription
      subscription if valid_subscription?(subscription)
    end

    def active_subscription?
      return true if sandboxd? || admin?

      sync_subscriptions
      payment_processor.present? && payment_processor.subscribed?
    end

    def valid_payment_processor?
      payment_processor && !payment_processor.deleted? && payment_processor.processor == 'stripe'
    end

    private

    def sync_subscriptions
      payment_processor.sync_subscriptions(status: 'all')
    rescue StandardError => e
      Rails.logger.error("Error syncing subscriptions: #{e.message}")
    end

    def valid_subscription?(subscription)
      subscription.present? && subscription.valid? && !subscription.cancelled?
    end
  end
end
