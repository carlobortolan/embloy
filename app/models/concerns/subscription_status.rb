# frozen_string_literal: true

# The SubscriptionStatus module provides methods for checking and updating
# the status of a user's subscription.
module SubscriptionStatus
  extend ActiveSupport::Concern
  included do
    def current_subscription_info
      subscription = payment_processor&.subscription
      subscription&.processor_subscription if subscription&.valid? && !subscription&.cancelled?
    end

    def current_subscription
      subscription = payment_processor&.subscription
      subscription if subscription&.valid? && !subscription&.cancelled?
    end

    def active_subscription
      if payment_processor.nil?
        false
      else
        payment_processor.subscribed?
      end
    end
  end
end
