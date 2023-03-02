class WelcomeMailer < ApplicationMailer
  def welcome_email

    @user = params[:user]
    @url = sign_in_url
    mail from: ENV['EMAIL_NOREPLY_USER'], to: @user.email, subject: 'Welcome to Embloy'
    # mail from: ENV['EMAIL_NOREPLY_USER'], to: @user.email, subject: 'Welcome to Embloy'
    # mail(to: @user.email, subject: 'Welcome to What\'s Next')
  end
end