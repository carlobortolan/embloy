# frozen_string_literal: true

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins ENV.fetch('CORS_CORE_CLIENT_URL', 'http://localhost:3000')
    resource '*', headers: :any, methods: %i[get post put patch delete options head]
  end
  allow do
    origins ENV.fetch('CORS_GENIUS_CLIENT_URL', 'http://localhost:3000')
    resource '*', headers: :any, methods: %i[get post]
  end
end
