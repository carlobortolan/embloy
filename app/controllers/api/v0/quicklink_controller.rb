# frozen_string_literal: true

# The QuicklinkController is responsible for handling the application process via the Embloy API.
# It includes methods for creating client and request tokens and applying for jobs via Quicklink.
module Api
  module V0
    # QuicklinkController handles quicklink-related actions
    class QuicklinkController < ApiController
      skip_before_action :set_current_user,
                         only: %i[create_request]
      skip_before_action :verify_authenticity_token, only: %i[create_request]

      before_action :verify_client_token,
                    only: [:create_request]
      before_action :verify_request_token,
                    only: [:apply]
      before_action :must_be_subscribed, only: [:create_client]

      # The apply method is responsible for handling the application process.
      # It finds the user and client based on the decoded tokens, updates or creates the job, and applies for the job.
      def apply
        begin
          @client = User.find(@decoded_request_token['sub'].to_i)
        rescue StandardError
          not_found_error('client')
        end

        update_or_create_job(@decoded_request_token['job'])
        apply_for_job
      end

      # The create_request method is responsible for creating a `request_token`.
      # It calls the Encoder class of the `QuicklinkService::Request` module to create the token.
      # It then returns the token in the response.
      def create_request
        return user_role_to_low_error unless must_be_verified(@decoded_client_token['sub'].to_i)
        return user_blocked_error unless user_not_blacklisted(@decoded_client_token['sub'].to_i)

        token = QuicklinkService::Request::Encoder.call(
          @decoded_client_token['sub'].to_i, 'job#1'
        )
        render status: 200,
               json: { 'request_token' => token }
      end

      # The create_client endpoint is responsible for creating a `client_token`.
      # It calls the Encoder class of the `QuicklinkService::Client` module to create the token.
      # It then returns the token in the response.
      def create_client
        verified!(@decoded_token['typ'])
        generate_and_render_token(check_subscription)
      end

      private

      # The apply_for_job method is responsible for creating a new application for a job.
      # It sets the `user_id`, `job_id`, `application_text`, `created_at`, `updated_at`, and `response` fields of the application.
      # If the application is saved successfully, it returns a success message.
      # If the application is not saved successfully, it raises a `malformed_error`.
      def apply_for_job
        puts "params #{params}"

        application = Application.create_from(
          Current.user.id, @job.job_id, params
        )

        begin
          application.user = Current.user
        rescue ActiveRecord::RecordNotFound
          raise CustomExceptions::InvalidUser::Unknown
        end

        if application.save
          render status: 200,
                 json: { message: 'Application submitted!' }
        else
          malformed_error('application')
        end
      end

      # The update_or_create_job method is responsible for updating an existing job or creating a new one.
      # It takes a `job_slug` as a parameter, which is used to find or create the job.
      # If the job does not exist, it is created with the `job_slug` and `client.id`.
      # The job is then added to the client's jobs.
      def update_or_create_job(job_slug)
        @client.jobs = [] if @client.jobs.nil?

        # TODO: Update to use shell / EMJ / job_slug
        @job = @client.jobs.find_by(title: job_slug)
        unless @job
          @job = Job.create_emj(job_slug, @client.id) # Create externally managed job, if it hasn't been created yet
          @job.user = @client
          @client.jobs << @job
        end
      rescue RecordNotFound
        not_found_error('job')
      end

      def parse_expiration_date
        Time.parse(params[:exp]) if params[:exp] && valid_time?(params[:exp])
      end

      def valid_time?(time_string)
        Time.parse(time_string)
        true
      rescue ArgumentError
        false
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
    end
  end
end
