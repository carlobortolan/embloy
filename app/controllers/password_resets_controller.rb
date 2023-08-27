class PasswordResetsController < ApplicationController
  skip_before_action :auth_prototype

  def new; end

  def create
    if params[:email].present?
      @user = User.find_by(email: params[:email])
      if @user.present?
        # send mail
        PasswordMailer.with(user: @user).reset.deliver_later
      end
      redirect_to root_path, notice: 'Please check your email to reset the password.'
    else
      redirect_to help_path, notice: 'Something went wrong. Try again.'
    end
  end

  def edit
    @user = User.find_signed!(params[:token], purpose: 'password_reset')
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    redirect_to sign_in_path, alert: 'Your token has expired. Please try again.'
  end

  def update
    @user = User.find_signed!(params[:token], purpose: 'password_reset')
    if @user.update!(password_params)
      redirect_to sign_in_path, notice: 'Your password was reset successfully. Please sign in.'
    else
      render :edit
    end
  end

  private

  def password_params
    params.require(:user).permit(:password, :password_confirmation)
  end
end
