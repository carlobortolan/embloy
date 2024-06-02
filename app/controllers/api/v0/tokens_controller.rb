# frozen_string_literal: true

module Api
  module V0
    # TokensController handles token-related actions
    class TokensController < ApiController
      before_action :set_token, only: %i[update destroy]

      def index
        tokens = Current.user.tokens.all
        tokens = tokens.where(active: true).where('expires_at > ?', Time.current) if show_params[:active] == '1'
        render(status: tokens.empty? ? 204 : 200, json: { tokens: })
      end

      def create
        token = build_token
        if token.save
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
        render status: 200, json: { message: 'Token deleted!' }
      end

      private

      def build_token
        token = Token.new(token_params)
        token.user = Current.user
        token.issuer = token.issuer.downcase
        token.issued_at ||= Date.today
        token.expires_at ||= determine_expiration(token.token_type, token.issuer)
        token
      end

      def determine_expiration(token_type, issuer)
        expiration_times = {
          'embloy' => { 'refresh_token' => 2.weeks, 'access_token' => 2.weeks },
          'lever' => { 'refresh_token' => 1.hour, 'access_token' => 1.year },
          'ashby' => { 'api_key' => 1.year }
        }

        expiration_time = expiration_times.dig(issuer, token_type)
        expiration_time ? Time.now + expiration_time : nil
      end

      def token_params
        params.permit(:name, :token_type, :issuer, :token, :issued_at, :expires_at, :active, :last_used_at, :scopes)
      end

      def show_params
        params.permit(:active)
      end
    end
  end
end
