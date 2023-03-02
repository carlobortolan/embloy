# frozen_string_literal: true
module Api
  module V0
    class UserController < ApplicationController
      protect_from_forgery with: :null_session

      def own_jobs
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
            jobs = User.find_by(id: decoded_token["sub"].to_i).jobs.order(created_at: :desc)
            if jobs.empty?
              render status: 204, json: { "jobs": jobs }
            else
              render status: 200, json: { "jobs": jobs }
            end

          rescue CustomException::Unauthorized::InsufficientRole
            render status: 403, json: { "user": [
              {
                "error": "ERR_INACTIVE",
                "description": "Attribute is blocked."
              }
            ]
            }

          rescue CustomException::InvalidInput::Token
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

      def own_applications
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
            applications = Application.all.where(user_id: decoded_token["sub"].to_i)
            if applications.empty?
              render status: 204, json: { "applications": applications }
            else
              render status: 200, json: { "applications": applications }
            end

            rescue CustomException::Unauthorized::InsufficientRole
              render status: 403, json: { "user": [
                {
                  "error": "ERR_INACTIVE",
                  "description": "Attribute is blocked."
                }
              ]
              }
            rescue CustomException::InvalidInput::Token
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
    end
  end
end

# frozen_string_literal: true
