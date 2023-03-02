# frozen_string_literal: true
module Api
  module V0
    class PasswordsController < ApiController

      def update
        begin
          if !password_params[:password].nil? && password_params[:password_confirmation].nil?
            render status: 400, json: { "password_confirmation": [
              {
                "error": "ERR_BLANK",
                "description": "Attribute can't be blank"
              }
            ]
            }
          elsif password_params[:password].nil? && !password_params[:password_confirmation].nil?
            render status: 400, json: { "password": [
              {
                "error": "ERR_BLANK",
                "description": "Attribute can't be blank"
              }
            ]
            }
          elsif password_params[:password].nil? && password_params[:password_confirmation].nil?
            render status: 400, json: { "password": [
              {
                "error": "ERR_BLANK",
                "description": "Attribute can't be blank"
              }
            ], "password_confirmation": [
              {
                "error": "ERR_BLANK",
                "description": "Attribute can't be blank"
              }
            ]
            }
          else

            if request.headers["HTTP_ACCESS_TOKEN"].nil?
              render status: 400, json: { "access_token": [
                {
                  "error": "ERR_BLANK",
                  "description": "Attribute can't be blank"
                }
              ]
              }
            else

              decoded_token = AuthenticationTokenService::Access::Decoder.call(request.headers["HTTP_ACCESS_TOKEN"])[0]
              UserRole.must_be_verified(decoded_token["typ"])
              if User.find_by(id: decoded_token["sub"]).update(password_params)
                render status: 200, json: { "message": "Password successfully updated!" }
              else
                render status: 422, json: { "password": [
                  {
                    "error": "ERR_INVALID",
                    "description": "Attribute couldn't get updated"
                  }
                ]
                }
              end

            end
          end

        rescue ActionController::ParameterMissing
          render status: 400, json: { "user": [
            {
              "error": "ERR_BLANK",
              "description": "Attribute can't be blank"
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

        rescue CustomExceptions::InvalidInput::Token
          render status: 400, json: { "access_token": [
            {
              "error": "ERR_INVALID",
              "description": "Attribute is malformed or unknown."
            }
          ]
          }
        rescue JWT::ExpiredSignature
          render status: 401, json: { "access_token": [
            {
              "error": "ERR_INVALID",
              "description": "Attribute has expired."
            }
          ]
          }
        rescue JWT::InvalidIssuerError
          render status: 401, json: { "access_token": [
            {
              "error": "ERR_INVALID",
              "description": "Attribute was signed by an unknown issuer."
            }
          ]
          }
        rescue JWT::VerificationError
          render status: 401, json: { "access_token": [
            {
              "error": "ERR_INVALID",
              "description": "Token can't be verified."
            }
          ]
          }
        rescue JWT::IncorrectAlgorithm
          render status: 401, json: { "access_token": [
            {
              "error": "ERR_INVALID",
              "description": "Token was encoded with an unknown algorithm."
            }
          ]
          }
        rescue JWT::DecodeError
          render status: 400, json: { "access_token": [
            {
              "error": "ERR_INVALID",
              "description": "Attribute is malformed or unknown."
            }
          ]
          }
        end
      end

      private

      def password_params
        params.require(:user).permit(:password, :password_confirmation)
      end
    end
  end
end
