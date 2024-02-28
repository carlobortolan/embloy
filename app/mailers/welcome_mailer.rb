# frozen_string_literal: true

# The WelcomeMailer handles sending welcome emails to new users.
class WelcomeMailer < ApplicationMailer
  def welcome_email
    @user = params[:user]
    @url = 'https://embloy.com/login'
    @token = params[:user].signed_id(purpose: 'activate_account', expires_in: 1.day)
    mail from: ENV.fetch('EMAIL_NOREPLY_USER', nil), to: @user.email, subject: 'Embloy - Welcome to Embloy'
  end

  def reactivate
    @user = params[:user]
    @url = 'https://embloy.com/login'
    @token = params[:user].signed_id(purpose: 'activate_account', expires_in: 1.day)
    mail from: ENV.fetch('EMAIL_NOREPLY_USER', nil), to: @user.email, subject: 'Embloy - Activation Link'
  end

  def notify_team
    @user = params[:user]
    @url = 'https://embloy.com/login'
    @token = params[:user].signed_id(purpose: 'activate_account')
    mail from: ENV.fetch('EMAIL_NOREPLY_USER', nil), to: 'carlobortolan@gmail.com', subject: "Embloy - #{@user.full_name} signed up"
  end
end
