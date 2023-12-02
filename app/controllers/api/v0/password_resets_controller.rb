# frozen_string_literal: true
module Api
  module V0
    class PasswordResetsController < ApiController

      def create
          verified!(@decoded_token["typ"])
          PasswordMailer.with(user: Current.user).reset.deliver_later
          render status: 200, json: { "message": "Password reset process initiated! Please check your mailbox." }
      end
      # edit/update methods are not implemented on purpose. this is due to the fact that a user must do the confirmation manually.
    end
  end
end