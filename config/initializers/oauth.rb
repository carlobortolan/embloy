Rails.application.config.middleware.use OmniAuth::Builder do
  provider :github, '560d1bd04ab07fd98e18', '36ef4918d833ed6213ef4639446ba708dfbdfc1b', scope: "user, email"
  # provider :github, ENV['GITHUB_KEY'], ENV['GITHUB_SECRET']
end

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2, '280969066348-aovpgj7fj2ei1miu7s4gbvhqveb0jans.apps.googleusercontent.com', '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'
end