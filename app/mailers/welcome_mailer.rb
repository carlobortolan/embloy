class WelcomeMailer < ApplicationMailer
  def welcome_email
    @user = params[:user]
    @url = sign_in_url
    @token = params[:user].signed_id(purpose: 'verify_account', expires_in: 15.minutes)
    mail from: ENV['EMAIL_NOREPLY_USER'], to: @user.email, subject: 'Welcome to Embloy'
    # mail from: ENV['EMAIL_NOREPLY_USER'], to: @user.email, subject: 'Welcome to Embloy'
    # mail(to: @user.email, subject: 'Welcome to What\'s Next')
  end
end