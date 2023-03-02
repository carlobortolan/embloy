class ApplicationMailer < ActionMailer::Base
  default from: ENV['EMAIL_NOREPLY_USER']
  layout "mailer"
end
