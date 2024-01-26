# frozen_string_literal: true

require 'json'

# The QuicklinkController is responsible for handling the application process via the Embloy API.
# It includes methods for creating client and request tokens and applying for jobs via Quicklink.
module Api
  module V0
    # QuicklinkController handles quicklink-related actions
    class QuicklinkController < ApiController
      include ApplicationBuilder

      skip_before_action :set_current_user, only: %i[create_request]

      before_action :verify_client_token, only: [:create_request]
      before_action :verify_request_token, only: %i[handle_request apply]
      before_action :must_be_subscribed, only: [:create_client]

      # The apply method is responsible for handling the application process.
      # It finds the user and client based on the decoded tokens, updates or creates the job, and applies for the job.
      # rubocop:disable Metrics/AbcSize
      def apply
        begin
          @client = User.find(@decoded_request_token['sub'].to_i)
        rescue StandardError
          return not_found_error('client')
        end

        session = @decoded_request_token['session']

        return render status: 401, json: { 'error' => 'Malformed Request Token' } if session.nil? || session['job_slug'].nil? || session['user_id'].nil? || session['subscription_type'].nil?

        session['referrer_url'] = request.referrer

        if update_or_create_job(session)
          apply_for_job
        else
          render status: 400, json: @job.errors.details
        end
      end

      # The apply method is responsible for handling the application process.
      # It finds the user and client based on the decoded tokens, updates or creates the job, and applies for the job.
      def handle_request
        begin
          @client = User.find(@decoded_request_token['sub'].to_i)
        rescue StandardError
          return not_found_error('client')
        end

        session = @decoded_request_token['session']

        return render status: 401, json: { 'error' => 'Malformed Request Token' } if session.nil? || session['job_slug'].nil? || session['user_id'].nil? || session['subscription_type'].nil?

        session['referrer_url'] = request.referrer

        if update_or_create_job(session)
          render status: 200, json: { session:, job: Job.json_for(@job) }
        else
          render status: 400, json: @job.errors.details
        end
      end
      # rubocop:enable Metrics/AbcSize

      # The create_request method is responsible for creating a `request_token`.
      # It calls the Encoder class of the `QuicklinkService::Request` module to create the token.
      # It then returns the token in the response.
      def create_request
        return user_role_to_low_error unless must_be_verified(@decoded_client_token['sub'].to_i)
        return user_blocked_error unless user_not_blacklisted(@decoded_client_token['sub'].to_i)
        return malformed_error('job_slug') if portal_params[:job_slug].nil?

        token = QuicklinkService::Request::Encoder.call(create_session)
        render status: 200, json: { 'request_token' => token }
      end

      # The create_client endpoint is responsible for creating a `client_token`.
      # It calls the Encoder class of the `QuicklinkService::Client` module to create the token.
      # It then returns the token in the response.
      def create_client
        #         verified!(@decoded_token['typ'])
        generate_and_render_token(check_subscription)
      end

      private

      # The update_or_create_job method is responsible for updating an existing job or creating a new one.
      # It takes a `job_slug` as a parameter, which is used to find or create the job.
      # If the job does not exist, it is created with the `job_slug` and `client.id`.
      # The job is then added to the client's jobs.
      def update_or_create_job(session)
        @client.jobs = [] if @client.jobs.nil?

        @job = @client.jobs.find_by(job_slug: session['job_slug'])
        unless @job
          allowed_params = %w[user_id job_type job_slug referrer_url duration code_lang title position description key_skills salary currency start_slot longitude latitude country_code postal_code
                              city address job_notifications cv_required allowed_cv_formats]
          @job = Job.new(session.slice(*allowed_params))
          return false unless @job.save

          @job.user = @client
          @client.jobs << @job
          return true

        end
        true
      end

      def parse_expiration_date
        Time.parse(create_client_params[:exp]) if create_client_params[:exp] && valid_time?(create_client_params[:exp])
      end

      def valid_time?(time_string)
        Time.parse(time_string)
        true
      rescue ArgumentError
        false
      end

      def create_session
        session = portal_params.to_unsafe_h.transform_keys(&:to_s)
        session['user_id'] = @decoded_client_token['sub'].to_i
        session['subscription_type'] = @decoded_client_token['typ']
        session
      end

      def check_subscription
        subscription = Current.user.current_subscription # Check for active subscription
        raise CustomExceptions::Subscription::ExpiredOrMissing if subscription.nil?

        subscription
      end

      def generate_and_render_token(subscription)
        token = QuicklinkService::Client::Encoder.call(
          Current.user.id, subscription, parse_expiration_date
        )
        render status: 200,
               json: { 'client_token' => token }
      end

      def create_client_params
        params.except(:format).permit(:exp)
      end

      def application_params
        params.except(:format).permit(:id, :application_text, :application_attachment)
      end

      def portal_params
        params.except(:format).permit(:mode, :success_url, :cancel_url, :job_slug, :title, :description, :start_slot, :longitude, :latitude, :job_type, :status, :image_url,
                                      :job_status, :position, :currency, :salary, :key_skills, :duration, :job_notifications, :cv_required, allowed_cv_formats: [])
      end
    end
  end
end
