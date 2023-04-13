# frozen_string_literal: true
module Api
  module V0
    class PasswordResetsController < ApiController
      before_action :verify_access_token

      def create
        begin
          verified!(@decoded_token["typ"])
          user = User.find(@decoded_token["sub"])
          PasswordMailer.with(user: user).reset.deliver_later
          render status: 200, json: { "message": "Password reset process initiated! Please check your mailbox." }

          rescue ActiveRecord::RecordNotFound # Thrown when there is no User for id token["sub"]
            not_found_error('user')
        end
      end
      # edit/update methods are not implemented on purpose. this is due to the fact that a user must do the confirmation manually.
    end
  end
end