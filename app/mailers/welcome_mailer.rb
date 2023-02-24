class WelcomeMailer < ApplicationMailer
  def welcome_email
    @user = params[:user]
    @url = sign_in_url
    mail(to: @user.email, subject: 'Welcome to What\'s Next')
  end
end