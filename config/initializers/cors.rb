# frozen_string_literal: true

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins ENV.fetch('CORS_CLIENT_URL', nil)
    resource '*', headers: :any, methods: %i[get post put patch delete options head]
  end

  allow do
    origins ENV.fetch('CORS_GENIUS_CLIENT_URL', nil)
    resource '*', headers: :any, methods: %i[get post]
  end

  # Allow all origins for /sdk/apply endpoint
  allow do
    origins '*'
    resource '/sdk/apply', headers: :any, methods: %i[get post put patch delete options head]
  end
end
