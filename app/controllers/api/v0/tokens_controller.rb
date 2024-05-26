# frozen_string_literal: true

module Api
  module V0
    # TokensController handles token-related actions
    class TokensController < ApplicationController
      before_action :set_token, only: %i[show update destroy]
      before_action :set_owner, except: %i[create]

      def index
        tokens = Current.user.tokens.all
        render(status: tokens.empty? ? 204 : 200, json: { tokens: })
      end

      def create
        token = Token.new(token_params)
        token.user = Current.user

        if token.save
          Current.user.tokens << token
          render(status: 201, json: { token: })
        else
          render status: 422, json: token.errors
        end
      end

      def update
        if @token.update(token_params)
          render(status: 200, json: { token: @token })
        else
          render status: 422, json: @token.errors
        end
      end

      def destroy
        @token.destroy
        render status: 200, json: { message: 'User deleted!' }
      end

      private

      def token_params
        params.require(:token).permit(:name, :type, :issuer, :token, :issued_at, :expires_at, :active, :last_used_at, :scopes)
      end
    end
  end
end
