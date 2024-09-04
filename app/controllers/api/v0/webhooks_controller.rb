# frozen_string_literal: true

module Api
  module V0
    # WebhooksController handles users' webhook-related actions
    class WebhooksController < ApiController
      def index
        webhooks = Current.user.webhooks
        render(status: webhooks.empty? ? 204 : 200, json: { webhooks: })
      end

      def refresh
        case refresh_params[:source]
        when 'lever'
          Integrations::LeverWebhooksController.refresh_webhooks(Current.user)
        when 'ashby'
          Integrations::AshbyWebhooksController.refresh_webhooks(Current.user)
        else
          render(status: 422, json: { error: 'Unknown source' }) and return
        end

        render(status: 200, json: { message: 'Webhooks refreshed successfully' })
      end

      private

      def refresh_params
        params.permit(:source)
      end
    end
  end
end
