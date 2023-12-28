# frozen_string_literal: true

# The ApplicationMailer is the base mailer class that other mailers inherit from.
class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch('EMAIL_NOREPLY_USER', nil)
  layout 'mailer'
end
