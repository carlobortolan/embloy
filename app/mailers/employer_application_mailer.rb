class EmployerApplicationMailer < ApplicationMailer
  def application_notification
    puts "STARTING SEND"
    puts "PARAMS = #{params}"
    @job = params[:job]
    @application = params[:application]
    @applicant = User.find(params[:job].user_id)
    @recipient = params[:recipient]
    puts "JOB = #{@job}"
    puts "APPLICATION = #{@application}"
    puts "APPLICANT = #{@applicant}"
    puts "RECIPIENT = #{@recipient}"

    puts "FINISHED PARSING"
    mail from: "noreply@embloy.com", to: "carlobortolan@gmail.com", subject: 'Welcome to Embloy'
    # mail from: ENV['EMAIL_NOREPLY_USER'], to: @recipient.email, subject: 'Welcome to Embloy'
    # mail from: ENV['EMAIL_NOREPLY_USER'], to: @user.email, subject: 'Welcome to Embloy'
    # mail(to: @user.email, subject: 'Welcome to What\'s Next')
  end

  # def application_accept_email
  #   @user = params[:user]
  #   @url = sign_in_url
  #   mail from: ENV['EMAIL_NOREPLY_USER'], to: @user.email, subject: 'Welcome to Embloy'
  #   mail from: ENV['EMAIL_NOREPLY_USER'], to: @user.email, subject: 'Welcome to Embloy'
  #   mail(to: @user.email, subject: 'Welcome to What\'s Next')
  # end

end
