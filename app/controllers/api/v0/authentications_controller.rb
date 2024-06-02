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
                    AuthenticationTokenService::Refresh::Encoder.call(@user, refresh_token_params['validity'])
                  else
                    AuthenticationTokenService::Refresh::Encoder.call(@user)
                  end

          render status: 200, json: { 'refresh_token' => token }
        end
        # ========== Rescue severe Exceptions ==========
      rescue ActionController::ParameterMissing
        blank_error('refresh_token')
        # ======== Overwrite APIExceptionHandler =======
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
    end
  end
end
