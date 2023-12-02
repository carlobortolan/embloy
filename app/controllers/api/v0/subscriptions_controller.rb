# frozen_string_literal: true
module Api
    module V0
      class SubscriptionsController < ApiController
        before_action :set_subscription, except: [:create, :get_all_subscriptions]

        def create
            verified!(@decoded_token["typ"])
            subscription = Subscription.new(subscription_params)
            subscription.user = Current.user
            if subscription.save
                render status: 200, json: { "message": "Subscription created!" }
            else
                malformed_error('subscription')
            end
        end

        def get_all_subscriptions
            verified!(@decoded_token["typ"])
            subscriptions = Current.user.subscriptions
            subscriptions.empty? ? render(status: 204, json: { "subscriptions": subscriptions }) : render(status: 200, json: { "subscriptions": subscriptions })
        end

        def get_subscription
            render(status: 200, json: { "subscription": @subscription })
        end

        def cancel_subscription
            if @subscription.update(active: false)
                render status: 200, json: { "message": "Subscription cancelled!" }
            else
                malformed_error('subscription')
            end
        end

        def activate_subscription
            if @subscription.activate
                render status: 200, json: { "message": "Subscription activated!" }
            else
                # Handle payment error
                malformed_error('subscription')
            end
        end

        def renew_subscription
            if @subscription.update(subscription_params)
                render status: 200, json: { "message": "Subscription renewed!" }
            else
                malformed_error('subscription')
            end
        end

        def delete_subscription
            if @subscription.destroy
                render status: 200, json: { "message": "Subscription deleted!" }
            else
                malformed_error('subscription')
            end
        end

        private
            def subscription_params
                params.permit(:type, :active, :expiration_date, :start_date, :auto_renew, :renew_date)
            end
        end
    end
end