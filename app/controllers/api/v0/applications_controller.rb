module Api
  module V0
    class ApplicationsController < ApiController

      def show
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
            job = Job.find(params[:id])
            applications = job.applications.find_by_sql("SELECT * FROM applications a WHERE a.user_id = #{decoded_token["sub"]} and a.job_id = #{params[:id]}")
            if applications.empty?
              render status: 204, json: { "applications": applications }
            else
              render status: 200, json: { "applications": applications }
            end

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

          rescue CustomExceptions::Unauthorized::InsufficientRole # thrown from ApplicationController.should_be_verified!
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
            job = Job.find(params[:id])
            application = Application.create!(
              user_id: decoded_token["sub"],
              job_id: job.job_id,
              application_text: "This application was submitted through the v.0 Embloy API",
              applied_at: Time.now,
              updated_at: Time.now,
              response: "No response yet..."
            )
            application.save!
            render status: 200, json: { "message": "Application submitted!" }

          rescue ActiveRecord::RecordNotUnique
            render status: 400, json: { "application": [
              {
                "error": "ERR_UNNECESSARY",
                "description": "Attribute is already submitted."
              }
            ]
            }

          rescue ActiveRecord::RecordNotFound
            if params[:id].nil?
              render status: 400, json: { "job": [
                {
                  "error": "ERR_BLANK",
                  "description": "Attribute can't be blank."
                }
              ]
              }
            else
              render status: 400, json: { "job": [
                {
                  "error": "ERR_INVALID",
                  "description": "Attribute is malformed or unknown."
                }
              ]
              }
            end

          rescue ActiveRecord::RecordInvalid
            render status: 400, json: { "application": [
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

          rescue CustomExceptions::Unauthorized::InsufficientRole # thrown from ApplicationController.should_be_verified!
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
        else
          begin
            decoded_token = AuthenticationTokenService::Access::Decoder.call(request.headers["HTTP_ACCESS_TOKEN"])[0]
            verified!(decoded_token["typ"])
            job = Job.find(params[:id])
            #application = job.applications.find(decoded_token["sub"])
            application = Application.find_by_sql("SELECT * FROM applications a WHERE a.user_id = #{decoded_token["sub"]} and a.job_id = #{params[:id]}")[0]
            application.destroy!

            render status: 200, json: { "message": "Application deleted!" }

          end
        end
        end


=begin
      def accept
        @job = Job.find(params[:job_id])
        if require_user_be_owner!
          # @application_service.accept(params[:job_id].to_i, params[:application_id].to_i, "ACCEPTED")
          redirect_to job_path(@job), status: :see_other, notice: 'Application has been accepted'
        end
      end

      def reject
        @job = Job.find(params[:job_id])
        if require_user_be_owner!
          # @application_service.reject(params[:job_id].to_i, params[:application_id].to_i, "REJECTED")
          redirect_to job_applications_path(params[:job_id]), status: :see_other, notice: 'Application has been rejected'
        end
      end

      def reject_all
        @job = Job.find(params[:job_id])
        if require_user_be_owner!
          # @application_service.reject_all(params[:job_id].to_i, "REJECTED")
          redirect_to job_path(@job), status: :see_other, notice: 'All Applications have been rejected'
        end
      end

      private

      def set_job
        @job = Job.find(params[:job_id])
      end
=end

    end
  end
end
