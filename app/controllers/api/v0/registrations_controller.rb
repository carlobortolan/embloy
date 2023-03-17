module Api
  module V0
    class RegistrationsController < ApiController

      def create
        begin
          @user = User.new(user_params)

          if @user.save
            render status: 200, json: { "message": "Account registered! Please activate your account and claim your refresh token via GET #{api_v0_user_verify_path} " }
          else
            # horrible code follows TODO: make prettier for v1
            # the problem is that I dont know a way to customize the error messages from bycrypt verification and i want to morphe them into the standard error render format
            taken = false
            @user.errors.details[:email].each do |e|
              if e[:error] == "ERR_TAKEN"
                taken = true
              end
            end
            if taken
              render status: 422, json: @user.errors.details
            else
              if @user.errors.details[:password].present? && @user.errors.details[:password][0][:error] == :too_long # auto verification of pw (by bycript) doesnt render as we need it. preliminary solution. should be tidied up in v1
                malformed_error('password')
              elsif @user.errors.details[:password].present? && @user.errors.details[:password][0][:error] == :blank # this one is just there to substitute the error:blank to error:ERR_BLANK in case password:""
                bin = @user.errors.details
                bin[:password][0][:error] = :ERR_BLANK
                render status: 400, json: bin
              elsif @user.errors.details[:password_confirmation].present? && @user.errors.details[:password_confirmation][0][:error] == :confirmation
                malformed_error('password_confirmation')
              else
                render status: 400, json: @user.errors.details
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

        end
      end

      def verify
        # verifies that an newly created account was created correctly. if so it issues an initial refresh token ()

        if !params[:email].present? && params[:password].present? # checks for fully missing as well as empty params
          blank_error('email')
        elsif params[:email].present? && !params[:password].present?
          blank_error('password')
        elsif !params[:email].present? && !params[:password].present?
          blank_error(%w[email password])
        else

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
              # Todo Exception handling
              @user.update_column("user_role", "verified")
              @user.update_column("activity_status", 1)

              token = AuthenticationTokenService::Refresh::Encoder.call(@user.id)

              render status: 200, json: { "refresh_token": token }
              # rescue # because the code above checked all attributes, there should not be any exceptions. if there are something strange happened (or a bug)
              # render status: 500, json: { "error": "Something went wrong while issuing your initial refresh token. Please try again later. If this error persists, we recommend to contact our support team." }
            else
              # is user already listed as active/is user verified?
              render status: 422, json: { "user": [
                {
                  "error": "ERR_UNNECESSARY",
                  "description": "Attribute is already verified"
                }
              ]
              }
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