# frozen_string_literal: true

Sentry.init do |config|
  config.dsn = 'https://12c937fcaf34f1a20c326c64aaec6961@o4507920163209216.ingest.de.sentry.io/4507920168845392'
  config.breadcrumbs_logger = %i[active_support_logger http_logger]

  # Set traces_sample_rate to 1.0 to capture 100%
  # of transactions for tracing.
  # We recommend adjusting this value in production.
  config.traces_sample_rate = 1.0
  # or
  config.traces_sampler = lambda do |_context|
    true
  end
  # Set profiles_sample_rate to profile 100%
  # of sampled transactions.
  # We recommend adjusting this value in production.
  config.profiles_sample_rate = 1.0
end
