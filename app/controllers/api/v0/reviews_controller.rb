module Api
  module V0

    class ReviewsController < ApiController

=begin
      def index
        if require_user_be_owner!
          @reviews = @user.reviews.all
        end
      end
=end

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
            if Review.all.where(:created_by => decoded_token["sub"], :subject => params[:id]).present?
              unnecessary_error('review')
            else
              decoded_token["sub"].to_i == params[:id].to_i ? raise(CustomExceptions::InvalidUser::Unknown) : false
              review_params["job_id"].present? ? must_be_owner!(review_params["job_id"], decoded_token["sub"]) : false
              review = Review.new(review_params)
              review.subject = params[:id]
              review.created_by = decoded_token["sub"]
              review.save!
              render status: 200, json: { "message": "Review submitted!" }
            end

          rescue ActionController::ParameterMissing
            blank_error('review')


          rescue ActiveRecord::StatementInvalid
            malformed_error('review')

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
            review = Review.find(params[:id])

            #Todo: Replace with general must_be_owner! method (if it then exist)
            ###############################################################################################################################
            review.created_by.to_i == User.find(decoded_token["sub"].to_i).id ? true : raise(CustomExceptions::Unauthorized::InsufficientRole::NotOwner)#
            ###############################################################################################################################

            review.assign_attributes(review_params)
            review.save!
            render status: 200, json: { "message": "Review updated!" }
          rescue ActionController::ParameterMissing
            render status: 400, json: { "review": [
              {
                "error": "ERR_BLANK",
                "description": "Attribute can't be blank"
              }
            ]
            }

          rescue ActiveRecord::RecordNotFound
            if params[:id].nil?
              render status: 400, json: { "review": [
                {
                  "error": "ERR_BLANK",
                  "description": "Attribute can't be blank."
                }
              ]
              }
            else
              render status: 400, json: { "review": [
                {
                  "error": "ERR_INVALID",
                  "description": "Attribute is malformed or unknown."
                }
              ]
              }
            end
          rescue ActiveRecord::StatementInvalid
            render status: 400, json: { "review": [
              {
                "error": "ERR_INVALID",
                "description": "Attribute is malformed or unknown."
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
          rescue CustomExceptions::Unauthorized::InsufficientRole
            render status: 403, json: { "user": [
              {
                "error": "ERR_INACTIVE",
                "description": "Attribute is blocked."
              }
            ]
            }
          rescue CustomExceptions::Unauthorized::InsufficientRole::NotOwner # thrown from ApplicationController::Job.must_be_owner!
            render status: 403, json: { "review": [
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
            review = Review.find(params[:id])

            #Todo: Replace with general must_be_owner! method (if it then exist)
            ###############################################################################################################################
            review.created_by.to_i == User.find(decoded_token["sub"].to_i).id ? true : raise(CustomExceptions::Unauthorized::InsufficientRole::NotOwner)#
            ###############################################################################################################################

            review.destroy!
            render status: 200, json: { "message": "Review deleted!" }

          rescue ActiveRecord::RecordNotFound
            if params[:id].nil?
              render status: 400, json: { "review": [
                {
                  "error": "ERR_BLANK",
                  "description": "Attribute can't be blank."
                }
              ]
              }
            else
              render status: 400, json: { "review": [
                {
                  "error": "ERR_INVALID",
                  "description": "Attribute is malformed or unknown."
                }
              ]
              }
            end
          rescue ActiveRecord::StatementInvalid
            render status: 400, json: { "review": [
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
          rescue CustomExceptions::Unauthorized::InsufficientRole
            render status: 403, json: { "user": [
              {
                "error": "ERR_INACTIVE",
                "description": "Attribute is blocked."
              }
            ]
            }
=begin
          rescue CustomExceptions::Unauthorized::InsufficientRole::NotOwner # thrown from ApplicationController::Job.must_be_owner!
            render status: 403, json: { "job": [
              {
                "error": "ERR_INACTIVE",
                "description": "Attribute is blocked."
              }
            ]
            }
=end
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

      def review_params
        params.require(:review).permit(:rating, :message, :job_id)
      end

    end
  end
end