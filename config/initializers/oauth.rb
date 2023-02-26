# NEVER PUSH TO REMOTE!
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :github, ENV["GITHUB_KEY"], ENV["GITHUB_SECRET"], scope: "user, email"
end

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2, ENV["GOOGLE_OAUTH2_KEY"], ENV["GOOGLE_OAUTH2_SECRET"]
end