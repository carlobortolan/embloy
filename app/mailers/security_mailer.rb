# frozen_string_literal: true

# The Security handles sending emails related to password and token changes.
class SecurityMailer < ApplicationMailer
  def reset
    @user = params[:user]
    @token = params[:user].signed_id(
      purpose: 'password_reset', expires_in: 15.minutes
    )
    mail from: ENV.fetch('EMAIL_NOREPLY_USER', nil), to: @user.email, subject: 'Embloy - Reset password'
  end

  def changed
    @user = params[:user]
    mail from: ENV.fetch('EMAIL_NOREPLY_USER', nil), to: @user.email, subject: 'Embloy - Password changed'
  end

  def otp
    @user = params[:user]
    @otp_token = params[:otp_token]
    mail(to: @user.email, subject: 'Embloy - Your verification code')
  end
end
