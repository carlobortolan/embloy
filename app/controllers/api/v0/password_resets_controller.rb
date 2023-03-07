# frozen_string_literal: true
module Api
  module V0
    class PasswordResetsController < ApiController
      before_action :verify_access_token

      def create
        begin
          verified!(@decoded_token["typ"])
          user = User.find(id: @decoded_token["sub"].to_i)
          PasswordMailer.with(user: user).reset.deliver_later
          render status: 200, json: { "message": "Password reset process successfully initiated! Please check your mailbox." }

        rescue ActionController::ParameterMissing
          blank_error('user')

        end
      end

      # edit/update methods are not implemented on purpose. this is due to the fact that a user must do the confirmation manually.

      private

      def password_params
        params.require(:user).permit(:password, :password_confirmation)
      end
    end
  end
end