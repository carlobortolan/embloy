require_relative '../../../../lib/feed_generator.rb'
module Api
  module V0
    class JobsController < ApiController
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
            verified!(decoded_token["typ"])
            @job = Job.new(job_params)
            @job.user_id = decoded_token["sub"]

            if @job.save
              render status: 200, json: { "message": "Job created!" }
            else
              render status: 400, json: { "error": @job.errors.details }
            end

          rescue ActionController::ParameterMissing
            render status: 400, json: { "job": [
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
      end

      def update
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
            verified!(decoded_token["typ"])
            must_be_owner!(params[:id], decoded_token["sub"])
            @job = Job.find_by(job_id: params[:id])
            @job.assign_attributes(job_params)
            if @job.save
              render status: 200, json: { "message": "Job updated!" }
            else
              render status: 400, json: { "error": @job.errors.details }
            end
          rescue ActionController::ParameterMissing # just relevant for strong parameters
            render status: 400, json: { "job": [
              {
                "error": "ERR_BLANK",
                "description": "Attribute can't be blank"
              }
            ]
            }

          rescue CustomExceptions::InvalidJob::Unknown
            render status: 400, json: { "job": [
              {
                "error": "ERR_INVALID",
                "description": "Attribute is malformed or unknown."
              }
            ]
            }

          rescue CustomExceptions::InvalidUser::Unknown
            render status: 400, json: { "user": [
              {
                "error": "ERR_INVALID",
                "description": "Attribute is malformed or unknown."
              }
            ]
            }

          rescue CustomExceptions::Unauthorized::InsufficientRole # thrown from ApplicationController.verified!
            render status: 403, json: { "user": [
              {
                "error": "ERR_INACTIVE",
                "description": "Attribute is blocked."
              }
            ]
            }

          rescue CustomExceptions::Unauthorized::InsufficientRole::NotOwner # thrown from ApplicationController::Job.must_be_owner!
            render status: 403, json: { "job": [
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

      def destroy
        if request.headers["HTTP_ACCESS_TOKEN"].nil?
          render status: 400, json: { "access_token": [
            {
              "error": "ERR_BLANK",
              "description": "Attribute can't be blank"
            }
          ]
          }
        elsif params[:id].nil?
          render status: 400, json: { "job": [
            {
              "error": "ERR_BLANK",
              "description": "Attribute can't be blank"
            }
          ]
          }
        else
          begin
            decoded_token = AuthenticationTokenService::Access::Decoder.call(request.headers["HTTP_ACCESS_TOKEN"])[0]
            verified!(decoded_token["typ"])
            #must_be_owner!(params[:id], decoded_token["sub"])
            job = Job.find_by(job_id: params[:id])
            job.destroy!
            render status: 200, json: { "message": "Job deleted!" }

          rescue CustomExceptions::InvalidJob::Unknown
            render status: 400, json: { "job": [
              {
                "error": "ERR_INVALID",
                "description": "Attribute is malformed or unknown."
              }
            ]
            }

          rescue CustomExceptions::InvalidUser::Unknown
            render status: 400, json: { "user": [
              {
                "error": "ERR_INVALID",
                "description": "Attribute is malformed or unknown."
              }
            ]
            }

          rescue CustomExceptions::Unauthorized::InsufficientRole # thrown from ApplicationController.verified!
            render status: 403, json: { "user": [
              {
                "error": "ERR_INACTIVE",
                "description": "Attribute is blocked."
              }
            ]
            }

          rescue CustomExceptions::Unauthorized::InsufficientRole::NotOwner # thrown from ApplicationController::Job.must_be_owner!
            render status: 403, json: { "job": [
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


      #parse_inputs isn't implemented because job_feed will be completly revised and then will this will be implemented accordingly

=begin
      def find
        @jobs = Job.all.where("status = 'public'").first(100)
      end

      def parse_inputs
        @my_args = { "longitude" => params[:longitude].to_f, "latitude" => params[:latitude].to_f, "radius" => params[:radius].to_f, "time" => Time.parse(params[:time]), "limit" => params[:limit].to_i }
        # TODO: REMOVE 'first(100)'
        @result = FeedGenerator.initialize_feed(Job.all.where("status = 'public'").first(100).as_json, @my_args)
      end
=end

      private

      def job_params
        params.require(:job).permit(:title, :description, :start_slot, :status, :longitude, :latitude)
      end


      #mark_notifications_as_read is not implemented because i dont understand how it works
=begin
      def mark_notifications_as_read
        if Current.user
          notifications_to_mark_as_read = @job.notifications_as_job.where(recipient: Current.user)
          notifications_to_mark_as_read.update_all(read_at: Time.zone.now)
        end
      end
=end
    end
  end
end