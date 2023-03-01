# frozen_string_literal: true
module Api
  module V0
    class UserController < ApplicationController
      protect_from_forgery with: :null_session

      def own_jobs
        begin
          if params[:access_token].nil?
            render status: 400, json: { "access_token": [
              {
                "error": "ERR_BLANK",
                "description": "Attribute can't be blank"
              }
            ]
            }
          else
            decoded_token = AuthenticationTokenService::Access::Decoder.call(params["access_token"])[0]
            if UserRole.must_be_verified(decoded_token["typ"])
              jobs = User.find_by(id: decoded_token["sub"].to_i).jobs.order(created_at: :desc)
              if jobs.empty?
                render status: 204, json: { "jobs": jobs }
              else
                render status: 200, json: { "jobs": jobs }
              end
            else
              render status: 403, json: { "user": [
                {
                  "error": "ERR_INACTIVE",
                  "description": "Attribute is blocked."
                }
              ]
              }
            end
          end
        rescue AuthenticationTokenService::InvalidInput::Token
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

      def own_applications
        begin
          if params[:access_token].nil?
            render status: 400, json: { "access_token": [
              {
                "error": "ERR_BLANK",
                "description": "Attribute can't be blank"
              }
            ]
            }
          else
            decoded_token = AuthenticationTokenService::Access::Decoder.call(params["access_token"])[0]
            if UserRole.must_be_verified(decoded_token["typ"])
              applications = Application.all.where(user_id: decoded_token["sub"].to_i)
              if applications.empty?
                render status: 204, json: { "applications": applications }
              else
                render status: 200, json: { "applications": applications }
              end

            else
              render status: 403, json: { "user": [
                {
                  "error": "ERR_INACTIVE",
                  "description": "Attribute is blocked."
                }
              ]
              }
            end
          end
        rescue AuthenticationTokenService::InvalidInput::Token
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


      def own_jobs_params
        params.require(:access_token)
      end

    end
  end
end

# frozen_string_literal: true
