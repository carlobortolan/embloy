# frozen_string_literal: true

require 'json'

# This module provides helper methods related to subscriptions.
module SubscriptionHelper
  STRIPE_PRICE_ID_TO_SUBSCRIPTION_TYPE = JSON.parse(File.read('app/helpers/subscription_types.json')).freeze
  SUBSCRIPTION_TYPE_TO_STRIPE_PRICE_ID = STRIPE_PRICE_ID_TO_SUBSCRIPTION_TYPE.invert.freeze

  def self.subscription_type(stripe_price_id)
    STRIPE_PRICE_ID_TO_SUBSCRIPTION_TYPE[stripe_price_id]
  end

  def subscription_type(stripe_price_id)
    STRIPE_PRICE_ID_TO_SUBSCRIPTION_TYPE[stripe_price_id]
  end

  def self.stripe_price_id(subscription_type)
    SUBSCRIPTION_TYPE_TO_STRIPE_PRICE_ID[subscription_type]
  end

  def stripe_price_id(subscription_type)
    SUBSCRIPTION_TYPE_TO_STRIPE_PRICE_ID[subscription_type]
  end

  def self.check_valid_mode(subscription_type, mode)
    raise CustomExceptions::InvalidInput::Quicklink::Mode::Malformed unless %w[job].include?(mode)
    raise CustomExceptions::Subscription::ExpiredOrMissing unless %w[premium enterprise_1 enterprise_2 enterprise_3].include?(subscription_type)
  end

  def check_valid_mode(subscription_type, mode)
    raise CustomExceptions::InvalidInput::Quicklink::Mode::Malformed unless %w[job].include?(mode)
    raise CustomExceptions::Subscription::ExpiredOrMissing unless %w[premium enterprise_1 enterprise_2 enterprise_3].include?(subscription_type)
  end
end
