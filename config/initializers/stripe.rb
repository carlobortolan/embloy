# frozen_string_literal: true

Rails.configuration.stripe = {
  publishable_key: ENV.fetch('STRIPE_PUBLISHABLE_KEY', nil),
  secret_key: ENV.fetch('STRIPE_SECRET_KEY', nil),
  webhook_secret: ENV.fetch('STRIPE_SIGNING_SECRET', nil)
}

Rails.configuration.after_initialize do
  Stripe.api_key = ENV.fetch('STRIPE_SECRET_KEY', nil)
end
