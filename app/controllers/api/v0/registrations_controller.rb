module Api
  module V0
    class RegistrationsController < APIController

      def create
        @user = User.new(user_params)
        begin
          if @user.save
            render status: 200, json: { "message": "Account registered! Please activate your account and claim your refresh token via GET #{api_v0_user_verify_path} " }

          else
            taken = false
            @user.errors.details[:email].each do |e|
              if e[:error] == "ERR_TAKEN"
                taken = true
              end
            end
            if taken
              render status: 422, json: { "error": @user.errors.details }
            else
              render status: 400, json: { "error": @user.errors.details }
            end
          end
        rescue
          render status: 500, json: { "error": "Please try again later. If this error persists, we recommend to contact our support team." }
        end
      end

      def verify
        # verifies that an newly created account was created correctly. if so it issues an initial refresh token ()

        if params[:email].nil? && !params[:password].nil?
          render status: 400, json: { "email": [
            {
              "error": "ERR_BLANK",
              "description": "Attribute can't be blank"
            }
          ]
          }
        elsif !params[:email].nil? && params[:password].nil?
          render status: 400, json: { "password": [
            {
              "error": "ERR_BLANK",
              "description": "Attribute can't be blank"
            }
          ]
          }
        elsif params[:email].nil? && params[:password].nil?
          render status: 400, json: { "email": [
            {
              "error": "ERR_BLANK",
              "description": "Attribute can't be blank"
            }
          ], "password": [
            {
              "error": "ERR_BLANK",
              "description": "Attribute can't be blank"
            }
          ]
          }

        else

          if !params[:email].nil? && !params[:password].nil?
            @user = User.find_by(email: params[:email])

            if !@user.present? || !@user.authenticate(params[:password])
              render status: 401, json: { "email||password": [
                {
                  "error": "ERR_INVALID",
                  "description": "Attribute is malformed or unknown"
                }
              ]
              }
            else

              if @user.activity_status == 0
                p @user.password_digest
                p "WLAN"
                @user.update_column("activity_status", 1)
                puts @user.errors.details

                begin
                  token = AuthenticationTokenService::Refresh::Encoder.call(@user.id)
                  render status: 200, json: { "refresh_token": token }
                rescue # because the code above checked all attributes, there should not be any exceptions. if there are something strange happened (or a bug)
                  render status: 500, json: { "error": "Something went wrong while issuing your initial refresh token. Please try again later. If this error persists, we recommend to contact our support team." }
                end
              else
                # is user already listed as active/is user verified?
                render status: 403, json: { "user": [
                  {
                    "error": "ERR_UNNECESSARY",
                    "description": "Attribute is already verified."
                  }
                ]
                }
              end

            end

          end
        end

      end

      private

      def user_params
        params.require(:user).permit(:email, :first_name, :last_name, :password, :password_confirmation)
      end

    end
  end
end