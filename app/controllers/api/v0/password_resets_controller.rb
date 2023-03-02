# frozen_string_literal: true
module Api
  module V0
    class PasswordResetsController < ApplicationController

      def create
        if request.headers["HTTP_ACCESS_TOKEN"].nil?
          render status: 400, json: { "access_token": [
            {
              "error": "ERR_BLANK",
              "description": "Attribute can't be blank"
            }
          ]
          }
        else
          begin
            decoded_token = AuthenticationTokenService::Access::Decoder.call(request.headers["HTTP_ACCESS_TOKEN"])[0]
             UserRole.must_be_verified(decoded_token["typ"])
              user = User.find_by(id: decoded_token["sub"].to_i)
              PasswordMailer.with(user: user).reset.deliver_later
              render status: 200, json: { "message": "Password reset process successfully initiated! Please check your mailbox." }

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
      end
      #edit/update methods are not implemented on purpose. this is due to the fact that a user must do the confirmation manually.


      private

      def password_params
        params.require(:user).permit(:password, :password_confirmation)
      end
    end
  end
end