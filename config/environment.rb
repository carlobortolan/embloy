# frozen_string_literal: true

# Load the Rails application.
require_relative 'application'

# Load environment variables
# env_var = File.join(Rails.root, 'config', 'env_var.rb')
# load(env_var) if File.exist?(env_var)

# Initialize the Rails application.
Rails.application.initialize!
