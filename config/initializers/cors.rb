# frozen_string_literal: true

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins ENV.fetch('CORS_CORE_CLIENT_URL', ''), ENV.fetch('CORS_GENIUS_CLIENT_URL', ''), 'localhost:3000', 'localhost:3001'
    resource '*',
             headers: :any,
             methods: %i[get post put patch delete options head]
  end

  allow do
    origins do |source, _env|
      source
    end
    resource '/api/v0/sdk/request/auth/token',
             headers: :any,
             methods: %i[get post put delete options head],
             credentials: true
  end
end
