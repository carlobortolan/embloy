class PasswordMailer < ApplicationMailer
  def reset
    @token = params[:user].signed_id(purpose: 'password_reset', expires_in: 15.minutes)
    mail from: ENV['EMAIL_NOREPLY_USER'], to: params[:user].email
  end
end
