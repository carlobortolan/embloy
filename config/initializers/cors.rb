# frozen_string_literal: true

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins 'embloy.com', 'api2.embloy.com', 'genius.embloy.com', 'localhost:3000', 'localhost:3001', 'localhost:8080'

    resource '*',
             headers: :any,
             methods: %i[get post put patch delete options head],
             credentials: true
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
