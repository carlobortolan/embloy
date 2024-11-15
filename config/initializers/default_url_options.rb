# frozen_string_literal: true

# Configure default URL options for the application
Rails.application.routes.default_url_options[:host] = 'localhost:3000'
Rails.application.routes.default_url_options[:protocol] = 'http'
