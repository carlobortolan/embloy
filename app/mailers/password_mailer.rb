# frozen_string_literal: true

# The PasswordMailer handles sending emails related to password changes.
class PasswordMailer < ApplicationMailer
  def reset
    @token = params[:user].signed_id(
      purpose: 'password_reset', expires_in: 15.minutes
    )
    puts "TOKEN FOR RESET: #{@token}"
    mail from: ENV.fetch('EMAIL_NOREPLY_USER', nil),
         to: params[:user].email, subject: 'Embloy - Reset Password'
  end
end
