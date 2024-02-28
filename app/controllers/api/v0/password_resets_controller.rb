# frozen_string_literal: true

module Api
  module V0
    # PasswordResetsController handles password reset-related actions
    class PasswordResetsController < ApiController
      skip_before_action :set_current_user

      def create
        if create_params[:email].present?
          @user = User.find_by(email: create_params[:email])
          PasswordMailer.with(user: @user).reset.deliver_later if !@user.nil? && user_not_blacklisted(@user.id) && @user.present?

          render status: 202, json: { message: 'Password reset process initiated! Please check your mailbox.' }
        else
          blank_error('email')
        end
      end

      def update
        @user = User.find_signed!(params[:token], purpose: 'password_reset')
        return blank_error('password') if password_blank?
        return blank_error('password_confirmation') if password_confirmation_blank?
        return user_blocked_error unless user_not_blacklisted(@user.id)

        update_password
      rescue ActionController::ParameterMissing
        blank_error('user') # should not be thrown
      rescue ActiveRecord::RecordInvalid # Thrown when password != password_confirmation
        mismatch_error('password|password_confirmation')
      rescue ActiveRecord::RecordNotFound
        not_found_error('user')
      rescue ActiveSupport::MessageVerifier::InvalidSignature
        render status: 400, json: { message: 'Token has either expired, has a purpose mismatch, is for another record, or has been tampered with' }
      end

      private

      def password_blank?
        password_params[:password].blank?
      end

      def password_confirmation_blank?
        password_params[:password_confirmation].blank?
      end

      def update_password
        @user.update!(password_params)
        render status: 200, json: { message: 'Your password was reset successfully. Please sign in.' }
      end

      def password_params
        params.require(:user).permit(:password, :password_confirmation)
      end

      def create_params
        params.except(:format).permit(:email)
      end
    end
  end
end
