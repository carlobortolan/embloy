class RegistrationsController < ApplicationController
  skip_before_action :auth_prototype

  def new
    @user = User.new
  end

  def find_coordinates
    if !user_params[:country_code].nil? && !user_params[:postal_code].nil? && !user_params[:city].nil? && !user_params[:address].nil?
      @user[:longitude] = 0.0
      @user[:latitude] = 0.0
    end
  end

  def create
    @user = User.new(user_params)
    find_coordinates
    #    @user[:user_role] = 0

    if @user.save
      WelcomeMailer.with(user: @user).welcome_email.deliver_later
      session[:user_id] = @user.id
      redirect_to root_path, notice: 'Successfully created account. Check your emails to verify your account.'
    else
      render :new
    end
  end

  def verify_account
      @user = User.find_signed!(params[:token], purpose: 'verify_account')
      # TODO: Change to "verified" when opening prototype to public.
      if @user.update!(user_role: "spectator")
        redirect_to sign_in_path, notice: 'Your account was verified successfully.'
      else
        render :edit
      end
  end

  private

  def user_params
    params.require(:user).permit(:email, :first_name, :last_name, :password, :password_confirmation, :longitude, :latitude, :country_code, :city, :postal_code, :address, :date_of_birth, :password_repeat, :application_notifications)
  end
end
