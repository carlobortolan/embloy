# frozen_string_literal: true

module Api
  module V0
    # PasswordsController handles password-related actions
    class PasswordsController < ApiController
      def update
        return blank_error('password') if password_params[:password].blank?
        return blank_error('password_confirmation') if password_params[:password_confirmation].blank?
        return user_role_to_low_error unless must_be_verified

        update_password
      rescue ActionController::ParameterMissing
        blank_error('user') # should not be thrown
      rescue ActiveRecord::RecordInvalid # Thrown when password != password_confirmation
        mismatch_error('password|password_confirmation')
      end

      private

      def update_password
        Current.user.update!(password_params)
        render status: 200, json: { message: 'Password updated' }
      end

      def password_params
        params.require(:user).permit(:password, :password_confirmation)
      end
    end
  end
end
