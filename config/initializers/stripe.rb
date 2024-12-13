# frozen_string_literal: true

Rails.configuration.stripe = if Rails.env.production?
                               {
                                 publishable_key: ENV.fetch('STRIPE_LIVE_PUBLISHABLE_KEY', nil),
                                 secret_key: ENV.fetch('STRIPE_LIVE_SECRET_KEY', nil),
                                 webhook_secret: ENV.fetch('STRIPE_LIVE_SIGNING_SECRET', nil)
                               }
                             else
                               {
                                 publishable_key: ENV.fetch('STRIPE_TEST_PUBLISHABLE_KEY', nil),
                                 secret_key: ENV.fetch('STRIPE_TEST_SECRET_KEY', nil),
                                 webhook_secret: ENV.fetch('STRIPE_TEST_SIGNING_SECRET', nil)
                               }
                             end

Rails.configuration.after_initialize do
  Stripe.api_key = Rails.configuration.stripe[:secret_key]
end
