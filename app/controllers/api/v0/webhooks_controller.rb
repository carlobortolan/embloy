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
        message = 'Webhooks refreshed successfully'

        case refresh_params[:source]
        when 'lever'
          message = Integrations::Lever::WebhooksController.refresh_webhooks(Current.user)
        when 'ashby'
          message = Integrations::Ashby::WebhooksController.refresh_webhooks(Current.user)
        else
          render(status: 422, json: { error: 'Unknown source' }) and return
        end

        render(status: 200, json: { message: })
      end

      private

      def refresh_params
        params.permit(:source)
      end
    end
  end
end
