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
              render status: 401, json: { "password": [
                {
                  "error": "ERR_INVALID",
                  "description": "Attribute is malformed or unknown."
                }
              ]
              }
            end

          else
            # User.find_by(email: refresh_token_params["email"]) fails
            render status: 400, json: { "user": [
              {
                "error": "ERR_INVALID",
                "description": "Attribute is malformed or unknown."
              }
            ]
            }
          end

          # ========== Rescue normal Exceptions ==========

        rescue CustomExceptions::Unauthorized::Blocked
          # The requested token subject (User) is blocked (blacklisted).
          render status: 403, json: { "user": [
            {
              "error": "ERR_INACTIVE",
              "description": "Attribute is blocked."
            }
          ]
          }

        rescue CustomExceptions::Unauthorized::InsufficientRole::NotVerified
          # The requested token subject (User) is unverified.
          render status: 403, json: { "user": [
            {
              "error": "ERR_INACTIVE",
              "description": "Attribute is not verified."
            }
          ]
          }

        rescue CustomExceptions::InvalidInput::CustomEXP
          # Invalid Input (Validity [man_interval] attribute is malformed)
          render status: 400, json: { "validity": [
            {
              "error": "ERR_INVALID",
              "description": "Attribute is malformed or unknown."
            }
          ]
          }

          # ========== Rescue severe Exceptions ==========
        rescue ActionController::ParameterMissing
          render status: 400, json: { "refresh_token": [
            {
              "error": "ERR_BLANK",
              "description": "Attribute can't be blank"
            }
          ]
          }
        rescue CustomExceptions::InvalidUser::Unknown
          # The requested token subject (User) doesn't exists BUT user.authenticate(refresh_token_params["password"]) says true
          render status: 500, json: { "user": [
            {
              "error": "ERR_SERVER",
              "description": "Please try again later. If this error persists please contact the support team."
            }
          ]
          }

        rescue CustomExceptions::InvalidInput::SUB
          # Invalid Input (User Attribute is malformed) BUT user.authenticate(refresh_token_params["password"]) says true
          render status: 500, json: { "user": [
            {
              "error": "ERR_SERVER",
              "description": "Please try again later. If this error persists please contact the support team."
            }
          ]
          }
        rescue CustomExceptions::InvalidUser::Unknown
          # Invalid User (User.find_by(id: id) == nil) BUT user.present says true
          render status: 500, json: { "user": [
            {
              "error": "ERR_SERVER",
              "description": "Please try again later. If this error persists please contact the support team."
            }
          ]
          }
        rescue CustomExceptions::Unauthorized::InsufficientRole
          render status: 403, json: { "user": [
            {
              "error": "ERR_INACTIVE",
              "description": "Attribute is blocked."
            }
          ]
          }
        end
      end

      def create_access

        begin

          # ============ Token gets claimed ==============
          if request.headers["HTTP_REFRESH_TOKEN"].nil?
            render status: 400, json: { "refresh_token": [
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

          # ========== Rescue normal Exceptions ==========
        rescue JWT::ExpiredSignature
          render status: 401, json: { "refresh_token": [
            {
              "error": "ERR_INVALID",
              "description": "Attribute has expired."
            }
          ]
          }
        rescue JWT::InvalidJtiError
          render status: 403, json: { "refresh_token": [
            {
              "error": "ERR_INACTIVE",
              "description": "Attribute is blocked."
            }
          ]
          }
        rescue CustomExceptions::InvalidInput::Token
          render status: 400, json: { "refresh_token": [
            {
              "error": "ERR_INVALID",
              "description": "Attribute is malformed or unknown."
            }
          ]
          }
          # ========== Rescue severe Exceptions ==========
        rescue JWT::InvalidIssuerError
          render status: 401, json: { "refresh_token": [
            {
              "error": "ERR_INVALID",
              "description": "Attribute was signed by an unknown issuer."
            }
          ]
          }
        rescue JWT::InvalidIatError
          render status: 401, json: { "refresh_token": [
            {
              "error": "ERR_INVALID",
              "description": "Attribute was timestamped incorrectly."
            }
          ]
          }
        rescue JWT::InvalidSubError
          render status: 401, json: { "refresh_token": [
            {
              "error": "ERR_INVALID",
              "description": "Attribute can't be allocated to an existing user."
            }
          ]
          }
        rescue JWT::VerificationError
          render status: 401, json: { "refresh_token": [
            {
              "error": "ERR_INVALID",
              "description": "Token can't be verified."
            }
          ]
          }
        rescue JWT::IncorrectAlgorithm
          render status: 401, json: { "refresh_token": [
            {
              "error": "ERR_INVALID",
              "description": "Token was encoded with an unknown algorithm."
            }
          ]
          }
        rescue CustomExceptions::Unauthorized::InsufficientRole
          render status: 403, json: { "user": [
            {
              "error": "ERR_INACTIVE",
              "description": "Attribute is blocked."
            }
          ]
          }
        rescue JWT::DecodeError
          render status: 400, json: { "refresh_token": [
            {
              "error": "ERR_INVALID",
              "description": "Attribute is malformed or unknown."
            }
          ]
          }

        end
      end

      private

      def refresh_token_params
        params.fetch(:refresh_token).permit(:email, :password, :validity)
      end

      def user
        # enables to not explicitly define user by just calling this method
        @user ||= User.find_by(email: refresh_token_params["email"])
      end
    end

  end
end
