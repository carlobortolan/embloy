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
        grant_type = access_token_params[:grant_type]
        refresh_token = access_token_params[:refresh_token]
        scope = "#{root_url}api.write"

        if grant_type != 'refresh_token' || refresh_token.nil?
          render status: 400, json: { error: 'Invalid request' }
        else
          render status: 200, json: {
            'access_token' => AuthenticationTokenService::Access::Encoder.call(refresh_token, scope),
            'token_type' => 'Bearer',
            'scope' => scope,
            'expires_in' => 20.minutes.to_i
          }
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

      def access_token_params
        params.permit(:grant_type, :refresh_token)
      end
    end
  end
end
