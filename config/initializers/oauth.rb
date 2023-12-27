# frozen_string_literal: true

# NEVER PUSH TO REMOTE!
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :github, ENV.fetch('GITHUB_KEY', nil), ENV.fetch('GITHUB_SECRET', nil), scope: 'user, email'
end

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2, ENV.fetch('GOOGLE_OAUTH2_KEY', nil), ENV.fetch('GOOGLE_OAUTH2_SECRET', nil)
end
