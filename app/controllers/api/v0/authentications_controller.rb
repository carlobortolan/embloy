module Api
  module V0
    class AuthenticationsController < ApiController
      def create_refresh
        begin

          if user.present?

            if user.authenticate(refresh_token_params["password"])

              # ============ Token gets claimed ==============
              if refresh_token_params["validity"].present? # is a custom token validity interval requested
                token = AuthenticationTokenService::Refresh::Encoder.call(user.id, refresh_token_params["validity"])
              else
                token = AuthenticationTokenService::Refresh::Encoder.call(user.id)
              end
              render status: 200, json: { "refresh_token" => token }

            else
              # user.authenticate(refresh_token_params["password"]) fails
              unauthorized_error('email|password')
            end

          else
            # User.find_by(email: refresh_token_params["email"]) fails
            unauthorized_error("email|password")
          end

          # ========== Rescue severe Exceptions ==========
        rescue ActionController::ParameterMissing
          blank_error('refresh_token')

          # ======== Overwrite APIExceptionHandler =======
        rescue CustomExceptions::InvalidUser::Unknown
          # The requested token subject (User) doesn't exists BUT user.authenticate(refresh_token_params["password"]) says true
          render status: 500, json: { "error": "Please try again later. If this error persists, we recommend to contact our support team." }

        rescue CustomExceptions::InvalidInput::SUB
          # Invalid Input (User Attribute is malformed) BUT user.authenticate(refresh_token_params["password"]) says true
          render status: 500, json: { "error": "Please try again later. If this error persists, we recommend to contact our support team." }
        rescue CustomExceptions::InvalidUser::Unknown
          # Invalid User (User.find_by(id: id) == nil) BUT user.present says true
          render status: 500, json: { "error": "Please try again later. If this error persists, we recommend to contact our support team." }
        end
      end

      def create_access

        begin

          # ============ Token gets claimed ==============
          if request.headers["HTTP_REFRESH_TOKEN"].nil? || request.headers["HTTP_REFRESH_TOKEN"].empty?
            render status: 400, json: { "token": [
              {
                "error": "ERR_BLANK",
                "description": "Attribute can't be blank"
              }
            ]
            }
          else
            token = AuthenticationTokenService::Access::Encoder.call(request.headers["HTTP_REFRESH_TOKEN"])
            # token = AuthenticationTokenService::Access::Encoder.call(access_token_params["refresh_token"])
            render status: 200, json: { "access_token" => token }

          end

        end
      end

      private

      def refresh_token_params
        params.fetch(:refresh_token).permit(:email, :password, :validity)
      end

      def user
        # enables to not explicitly define user by just calling this method
        if refresh_token_params["email"].nil? || refresh_token_params["email"].empty? || refresh_token_params["password"].nil? || refresh_token_params["password"].empty?
          raise CustomExceptions::InvalidInput::BlankCredentials
        else
          @user ||= User.find_by(email: refresh_token_params["email"])
        end
      end
    end

  end
end
