# frozen_string_literal: true

module Api
  module V0
    # CheckoutsController handles checkout-related actions
    class CheckoutsController < ApiController
      # skip_before_action :set_current_user, only: %i[paymentsuccess subscriptionsuccess failure] # TODO: Maybe change in the future, if neccessary

      def show
        setup_payment_processor
        stripe_price_id = SubscriptionHelper.stripe_price_id(checkout_params[:tier])
        render json: { error: 'Invalid tier: must be one of basic, premium, enterprise_1, enterprise_2 or enterprise_3' }, status: 400 and return if stripe_price_id.nil?

        create_checkout_session(determine_success_url, determine_cancel_url, stripe_price_id)
      rescue Stripe::StripeError => e
        render json: { error: e.message }, status: 400
      end

      # TODO: Check that payment doesn't already exist
      # TODO: Redirect to client
      def paymentsuccess
        session_id = checkout_params[:session_id]

        # Retrieve the session and line items
        session = Stripe::Checkout::Session.retrieve(session_id)
        line_items = Stripe::Checkout::Session.list_line_items(session_id)

        # Retrieve the Payment Intent ID from the session
        payment_intent_id = session.payment_intent

        # Retrieve the Payment Intent
        payment_intent = Stripe::PaymentIntent.retrieve(payment_intent_id)

        # Retrieve the ID of the latest charge associated with the Payment Intent
        charge_id = payment_intent.latest_charge

        # Retrieve details of the latest charge
        charge = Stripe::Charge.retrieve(charge_id)

        render status: 201, json: { message: 'Payment created!', charge:, session:, line_items: }
      rescue Stripe::StripeError => e
        render json: { error: e.message }, status: 400
      end

      # TODO: Check that subscription doesn't already exist
      # TODO: Redirect to client
      def subscriptionsuccess
        session = Stripe::Checkout::Session.retrieve(checkout_params[:session_id])
        line_items = Stripe::Checkout::Session.list_line_items(checkout_params[:session_id])

        # Parse subscription details from session/line_items
        # subscription = Current.user.payment_processor&.subscription&.processor_subscription

        render status: 201, json: { message: 'Subscription created!', session:, line_items: }
      rescue Stripe::StripeError => e
        render json: { error: e.message }, status: 400
      end

      # TODO: Redirect to client
      def failure; end

      def billing; end

      def portal
        if Current.user.payment_processor.nil?
          raise CustomExceptions::Subscription::ExpiredOrMissing and return # TODO: Move to application_controller.rb
        end

        begin
          # portal_session = Current.user.payment_processor.billing_portal
          default_customer = Current.user.pay_customers.find_by(default: true)

          if default_customer
            portal_session = Stripe::BillingPortal::Session.create(
              customer: default_customer.processor_id,
              return_url: 'https://genius.embloy.com'
            )
            render json: { portal_session: }, status: 200
          else
            render json: { error: 'No default customer found' }, status: 404
          end
        rescue Stripe::StripeError => e
          render json: { error: e.message }, status: 400
        end
      end

      private

      def checkout_params
        params.except(:format).permit(:payment_mode, :tier, :origin, :session_id)
      end

      def determine_success_url
        case checkout_params[:origin]
        when 'core'
          "#{ENV.fetch('CORE_CLIENT_URL', '')}/dashboard/billing"
        when 'genius'
          "#{ENV.fetch('GENIUS_CLIENT_URL', '')}/dashboard/billing"
        else
          api_v0_checkout_failure_url
        end
      end

      def determine_cancel_url
        case checkout_params[:origin]
        when 'core'
          "#{ENV.fetch('GENIUS_CLIENT_URL', '')}/dashboard/billing"
        when 'genius'
          "#{ENV.fetch('CORE_CLIENT_URL', '')}/dashboard/billing"
        else
          api_v0_checkout_failure_url
        end
      end

      def create_checkout_session(success_url, cancel_url, stripe_price_id)
        if !Current.user.payment_processor.nil? && !Current.user.payment_processor.deleted?
          session = Current.user.payment_processor.checkout(
            mode: checkout_params[:payment_mode],
            line_items: stripe_price_id,
            success_url:,
            cancel_url:
          )
          render json: session, status: 200
        else
          render json: { error: 'User or payment processor not found' }, status: 404
        end
      end

      def setup_payment_processor
        Current.user.set_payment_processor :stripe
        Current.user.pay_customers
        Current.user.payment_processor.customer
      end
    end
  end
end
