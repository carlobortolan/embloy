# frozen_string_literal: true

# The WelcomeMailer handles sending welcome emails to new users.
class WelcomeMailer < ApplicationMailer
  def welcome_email
    @user = params[:user]
    @url = sign_in_url
    @token = params[:user].signed_id(purpose: 'verify_account')
    mail from: ENV['EMAIL_NOREPLY_USER'],
         to: @user.email, subject: 'Embloy - Welcome to Embloy'
  end

  def notify_team
    @user = params[:user]
    @url = sign_in_url
    @token = params[:user].signed_id(purpose: 'activate_account')
    # mail from: ENV['EMAIL_NOREPLY_USER'], to: ENV['EMAIL_INFO_USER'], subject: "Embloy - #{@user.full_name} signed up."
    mail from: ENV['EMAIL_NOREPLY_USER'], to: 'carlobortolan@gmail.com',
         subject: "Embloy - #{@user.full_name} signed up"
  end
end
