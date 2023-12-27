# frozen_string_literal: true

module Api
  # V0 module
  module V0
    # RegistrationsController handles user registration actions
    class RegistrationsController < ApiController
      skip_before_action :set_current_user

      def create
        @user = User.new(user_params)

        if @user.save
          render status: 201, json: { "message": "Account registered! Please activate your account and claim your refresh token via GET #{api_v0_user_verify_path} " }
        else
          handle_errors
        end
      rescue ActionController::ParameterMissing
        render status: 400, json: { "user": [
          {
            "error": 'ERR_BLANK',
            "description": "Attribute can't be blank"
          }
        ] }
      end

      # TODO: @cb [User verification #73]
      def verify
        email, password = ActionController::HttpAuthentication::Basic.user_name_and_password(request)

        if !email.present? && password.present? # checks for fully missing as well as empty params
          blank_error('email')
          return
        elsif email.present? && !password.present?
          blank_error('password')
          return
        elsif !email.present? && !password.present?
          blank_error(%w[email password])
          return
        end

        @user = User.find_by(email:)

        return unauthorized_error('email|password') unless @user.present? && @user.authenticate(password)

        user_blocked_error and return unless user_not_blacklisted(@user.id)

        return unnecessary_error('user') unless @user.activity_status.zero?

        update_user_status(email, password)
        issue_refresh_token
      end

      def user_params
        params.require(:user).permit(:email, :first_name, :last_name, :password, :password_confirmation)
      end

      private

      def handle_errors
        if email_taken?
          render(status: 422, json: @user.errors.details) and return
        elsif password_too_long? || password_blank?
          handle_password_errors and return
        elsif password_confirmation_error?
          malformed_error('password_confirmation') and return
        else
          render(status: 400, json: @user.errors.details) and return
        end
      end

      def handle_invalid_credentials(user, password)
        return if user.present? && user.authenticate(password)

        unauthorized_error('email|password')
      end

      def email_taken?
        @user.errors.details[:email].any? { |e| e[:error] == 'ERR_TAKEN' }
      end

      def password_too_long?
        password_error?(:too_long)
      end

      def password_blank?
        password_error?(:blank)
      end

      def password_error?(error)
        @user.errors.details[:password].present? && @user.errors.details[:password][0][:error] == error
      end

      def handle_password_errors
        if password_blank?
          bin = @user.errors.details
          bin[:password][0][:error] = :ERR_BLANK
          render status: 400, json: bin
        else
          malformed_error('password')
          nil
        end
      end

      def password_confirmation_error?
        @user.errors.details[:password_confirmation].present? && @user.errors.details[:password_confirmation][0][:error] == :confirmation
      end

      def handle_blank_credentials(email, password)
        if !email.present? && password.present? # checks for fully missing as well as empty params
          blank_error('email')
          false
        elsif email.present? && !password.present?
          blank_error('password')
          false
        elsif !email.present? && !password.present?
          blank_error(%w[email password])
          false
        end
        true
      end

      def update_user_status(email, password)
        @user = User.find_by(email:)

        unauthorized_error('email|password') if !@user.present? || !@user.authenticate(password)

        user_blocked_error and return unless user_not_blacklisted(@user.id)
        return unless @user.activity_status.zero?

        # TODO: Exception handling
        @user.update_column('user_role', 'verified')
        @user.update_column('activity_status', 1)
      end

      def issue_refresh_token
        token = AuthenticationTokenService::Refresh::Encoder.call(@user.id)

        render status: 200, json: { "refresh_token": token }
      end
    end
  end
end
