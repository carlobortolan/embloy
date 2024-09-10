# frozen_string_literal: true

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins ENV.fetch('CORS_CORE_CLIENT_HOST', nil), ENV.fetch('CORS_GENIUS_CLIENT_HOST', nil), ENV.fetch('CORS_GENIUS_SERVER_HOST', nil), 'localhost:3000', 'localhost:3001', 'localhost:3002',
            'localhost:8080'

    resource '*',
             headers: :any,
             methods: %i[get post put patch delete options head],
             credentials: true
  end

  allow do
    origins '*'
    resource '/api/v0/sdk/request/auth/token',
             headers: :any,
             methods: %i[get post put delete options head]
  end

  allow do
    origins ENV.fetch('CORS_PROXY_SERVER_HOST', nil), 'localhost:8081'
    resource '/api/v0/sdk/request/auth/proxy',
             headers: :any,
             methods: %i[post options]
  end
end
