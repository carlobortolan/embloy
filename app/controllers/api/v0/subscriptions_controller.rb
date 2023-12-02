# frozen_string_literal: true
module Api
    module V0
      class SubscriptionsController < ApiController
        before_action :set_subscription, except: [:create, :get_all_subscriptions]

        def create
            verified!(@decoded_token["typ"])
            subscription = Subscription.new(create_subscription_params)
            subscription.user = Current.user
            if subscription.save
                render status: 201, json: { "message": "Subscription created!" }
            else
                render status: 400, json: { "subscription": subscription.errors}
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
            if @subscription.cancel
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
            if @subscription.renew
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
          def create_subscription_params
            params.require(:subscription).permit(:tier, :active, :expiration_date, :start_date, :auto_renew, :renew_date, :user_id)
          end
        
        end
    end
end