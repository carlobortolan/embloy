# NEVER PUSH TO REMOTE!
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :github, '560d1bd04ab07fd98e18', '36ef4918d833ed6213ef4639446ba708dfbdfc1b', scope: "user, email"
  # provider :github, '207c4c538c840956b011', 'bbbae3f347b2dae7a85c62f23f8b3e3a79810123', scope: "user, email"
  # provider :github, ENV["GITHUB_KEY"], ENV["GITHUB_SECRET"]
end

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2, '280969066348-aovpgj7fj2ei1miu7s4gbvhqveb0jans.apps.googleusercontent.com', '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'
  # provider :google_oauth2, '280969066348-g036daovajogpcu444itd3een858q5nb.apps.googleusercontent.com', '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'
  # provider :google_oauth2, ENV["GOOGLE_OAUTH2_KEY"], ENV["GOOGLE_OAUTH2_SECRET"]
end