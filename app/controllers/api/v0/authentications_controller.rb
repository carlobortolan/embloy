# frozen_string_literal: true

module Api
  module V0
    # This controller is responsible for the authentication of the user.
    class AuthenticationsController < ApiController
      skip_before_action :set_current_user

      def create_refresh
        email, password = ActionController::HttpAuthentication::Basic.user_name_and_password(request)
        # ============ Are all essential ===============
        # ============ credentials there? ==============
        if !email.present? && password.present? # checks for fully missing as well as empty params
          blank_error('email')
        elsif email.present? && !password.present?
          blank_error('password')
        elsif !email.present? && !password.present?
          blank_error(%w[email password])
        else

          # ============== Are credentials ===============
          # ================= correct? ===================
          @user = User.find_by(email:)
          return unauthorized_error('email|password') if !@user.present? || !@user.authenticate(password)

          # ============ Token gets claimed ==============
          token = if refresh_token_params['validity'].present? # is a custom token validity interval requested
                    AuthenticationTokenService::Refresh::Encoder.call(@user.id, refresh_token_params['validity'])
                  else
                    AuthenticationTokenService::Refresh::Encoder.call(@user.id)
                  end

          render status: 200, json: { 'refresh_token' => token }
        end
        # ========== Rescue severe Exceptions ==========
      rescue ActionController::ParameterMissing
        blank_error('refresh_token')
        # ======== Overwrite APIExceptionHandler =======
      rescue CustomExceptions::InvalidUser::Unknown
        # The requested token subject (User) doesn't exists BUT user.authenticate(refresh_token_params["password"]) says true
        render status: 500, json: { error: 'Please try again later. If this error persists, we recommend to contact our support team.' }
      rescue CustomExceptions::InvalidInput::SUB
        # Invalid Input (User Attribute is malformed) BUT user.authenticate(refresh_token_params["password"]) says true
        render status: 500, json: { error: 'Please try again later. If this error persists, we recommend to contact our support team.' }
      end

      def create_access
        # ============ Token gets claimed ==============
        if request.headers['HTTP_REFRESH_TOKEN'].nil? || request.headers['HTTP_REFRESH_TOKEN'].empty?
          render status: 400, json: { token: [
            {
              error: 'ERR_BLANK',
              description: "Attribute can't be blank"
            }
          ] }
        else
          token = AuthenticationTokenService::Access::Encoder.call(request.headers['HTTP_REFRESH_TOKEN'])
          # token = AuthenticationTokenService::Access::Encoder.call(access_token_params["refresh_token"])
          render status: 200, json: { 'access_token' => token }

        end
      end

      private

      def refresh_token_params
        # params.fetch(:refresh_token).permit(:validity)
        if params.key?(:refresh_token)
          params.require(:refresh_token).permit(:validity)
        else
          {}
        end
      end

      def user
        # enables to not explicitly define user by just calling this method
        if refresh_token_params['email'].nil? || refresh_token_params['email'].empty? || refresh_token_params['password'].nil? || refresh_token_params['password'].empty?
          raise CustomExceptions::InvalidInput::BlankCredentials
        end

        @user ||= User.find_by(email: refresh_token_params['email'])
      end
    end
  end
end
