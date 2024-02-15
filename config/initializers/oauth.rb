# frozen_string_literal: true

OmniAuth.config.allowed_request_methods = %i[post get]
OmniAuth.config.silence_get_warning = true

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :github, ENV.fetch('GITHUB_KEY', nil), ENV.fetch('GITHUB_SECRET', nil), scope: 'user,email'
end

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2, ENV.fetch('GOOGLE_OAUTH2_KEY', nil), ENV.fetch('GOOGLE_OAUTH2_SECRET', nil)
end

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :azure_activedirectory_v2, client_id: ENV.fetch('AZURE_CLIENT_ID', nil), client_secret: ENV.fetch('AZURE_CLIENT_SECRET', nil)
end

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :linkedin, client_id: ENV.fetch('LINKEDIN_APP_ID', nil), client_secret: ENV.fetch('LINKEDIN_APP_SECRET', nil)
end
