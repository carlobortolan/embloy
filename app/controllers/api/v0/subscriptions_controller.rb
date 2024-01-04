# frozen_string_literal: true

module Api
  module V0
    # SubscriptionsController handles subscription-related actions
    class SubscriptionsController < ApiController
      before_action :must_be_subscribed,
                    except: %i[all_subscriptions all_charges]

      def all_subscriptions
        must_be_verified!
        if Current.user.payment_processor
          subscriptions = Current.user.payment_processor.sync_subscriptions(status: 'all')
          if subscriptions.empty?
            render(status: 204, json: { subscriptions: [] })
          else
            render(
              status: 200, json: { subscriptions: }
            )
          end
        else
          render(status: 404, json: { error: 'User or payment processor not found' })
        end
      end

      def active_subscription
        must_be_verified!
        subscription = if params[:info].present? && params[:info] == '1'
                         Current.user.current_subscription_info
                       else
                         Current.user.current_subscription
                       end

        if subscription.nil?
          render(status: 404, json: { message: 'No active subscription found.' })
        else
          render(status: 200, json: { subscription: })
        end
      end

      def all_charges
        must_be_verified!
        charges = Current.user.charges
        if charges.empty?
          render(status: 204, json: { charges: })
        else
          render(status: 200, json: { charges: })
        end
      end
    end
  end
end
