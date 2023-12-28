# frozen_string_literal: true

module Api
  module V0
    # SubscriptionsController handles subscription-related actions
    class SubscriptionsController < ApiController
      before_action :set_subscription,
                    except: %i[create all_subscriptions]

      def all_subscriptions
        must_be_verified!
        subscriptions = Current.user.subscriptions
        if subscriptions.empty?
          render(status: 204,
                 json: { subscriptions: })
        else
          render(
            status: 200, json: { subscriptions: }
          )
        end
      end

      def create
        must_be_verified!
        subscription = Subscription.new(create_subscription_params)
        subscription.user = Current.user
        if subscription.save
          render status: 201,
                 json: { message: 'Subscription created!' }
        else
          render status: 400,
                 json: { subscription: subscription.errors }
        end
      end

      def subscription
        render(status: 200,
               json: { subscription: @subscription })
      end

      def cancel_subscription
        if @subscription.cancel
          render status: 200,
                 json: { message: 'Subscription cancelled!' }
        else
          malformed_error('subscription')
        end
      end

      def activate_subscription
        if @subscription.activate
          render status: 200,
                 json: { message: 'Subscription activated!' }
        else
          # Handle payment error
          malformed_error('subscription')
        end
      end

      def renew_subscription
        if @subscription.renew
          render status: 200,
                 json: { message: 'Subscription renewed!' }
        else
          malformed_error('subscription')
        end
      end

      def delete_subscription
        if @subscription.destroy
          render status: 200,
                 json: { message: 'Subscription deleted!' }
        else
          malformed_error('subscription')
        end
      end

      private

      def create_subscription_params
        params.require(:subscription).permit(:tier, :active, :expiration_date, :start_date, :auto_renew,
                                             :renew_date)
      end
    end
  end
end
