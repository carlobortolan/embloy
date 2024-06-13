# frozen_string_literal: true

#########################################################
#################### API CONTROLLER #####################
#########################################################

module Api
  module V0
    # ApiController handles API-related actions
    class ApiController < ApplicationController
      include ApiExceptionHandler

      # ============== API BEFORE ACTIONS ================
      before_action :set_current_user
      before_action :require_user_not_blacklisted!, unless: -> { Current.user.nil? }

      # ============== API CONTROLLER HELPERS ================
      # Set current user of the API to the user found in the access_token
      # Set current user to nil if no token is provided
      def set_current_user
        if bearer_token_blank?
          blank_error('token')
        else
          set_user_from_token
          begin
            check_scope(@decoded_bearer_token['scope'], request.path, request.method_symbol.to_s.upcase)
          rescue StandardError => e
            access_denied_error('token', e.message)
          end
        end
      end

      # Set queried subscription to @subscription to avoid code duplication
      # def set_subscription
      #  return if Current.user.nil?#
      #
      #  must_be_verified!
      #  set_user_subscription
      # end

      # ============== API TOKEN VERIFICATIOn ================
      def verify_client_token
        client_token_blank? ? blank_error('client token') : decode_client_token
      end

      def verify_request_token
        request_token_blank? ? blank_error('request token') : decode_request_token
      end

      # ============== API PATH VERIFICATIOn ================
      def verify_path_job_id
        if id_blank_or_invalid?
          blank_error('job')
        else
          validate_job_id
        end
      end

      def verify_path_active_job_id
        if id_blank_or_invalid?
          blank_error('job')
        else
          validate_active_job_id
        end
      end

      def verify_path_listed_job_id
        if id_blank_or_invalid?
          blank_error('job')
        else
          validate_listed_job_id
        end
      end

      def verify_path_user_id
        if id_blank_or_invalid?
          blank_error('user')
        else
          validate_user_id
        end
      end

      def verify_path_notification_id
        if id_blank_or_invalid?
          blank_error('notification')
        else
          validate_notification_id
        end
      end

      def verify_path_token_id
        if id_blank_or_invalid?
          blank_error('token')
        else
          set_token
        end
      end

      private

      def bearer_token_blank?
        bearer_token.nil? || bearer_token.empty?
      end

      def client_token_blank?
        request.headers['HTTP_CLIENT_TOKEN'].nil? || request.headers['HTTP_CLIENT_TOKEN'].empty?
      end

      def request_token_blank?
        request.headers['HTTP_REQUEST_TOKEN'].nil? || request.headers['HTTP_REQUEST_TOKEN'].empty?
      end

      def id_blank_or_invalid?
        params[:id].nil? || params[:id].empty? || params[:id].blank? || params[:id] == ':id'
      end

      def set_user_from_token
        @decoded_bearer_token = AuthenticationTokenService::Access::Decoder.call(bearer_token)[0]
        begin
          Current.user = (@decoded_bearer_token['sub'].to_i.zero? ? nil : User.find(@decoded_bearer_token['sub'].to_i))
        rescue ActiveRecord::RecordNotFound
          not_found_error('user')
        end
      end

      def check_scope(scope, path, method) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
        # Extract the base URL, the resource, and the permission from the scope
        # resource = scope.split('.').second_to_last.split('/').drop(2).join('/').prepend('/')
        resource = scope&.split('//')&.last&.split('/')&.drop(2)&.join('/')&.split('.')&.first&.prepend('/')

        permission = scope&.split('.')&.last

        raise "The scope '#{scope}' is not allowed because it does not match the application's base URL." unless URI.parse(scope).host == URI.parse(root_url).host

        # Check if the resource matches the requested path
        raise "The requested path '#{path}' for resource #{resource} and scope #{scope} is not allowed for scope '#{scope}'." unless path.match?(%r{/api/v\d+#{resource}.*})

        # Check if the permission matches the requested HTTP method
        allowed_methods = case permission
                          when 'read'
                            ['GET']
                          when 'write'
                            %w[GET POST PATCH PUT DELETE]
                          else
                            []
                          end

        return if allowed_methods.include?(method)

        raise "The scope '#{scope}' is not allowed to perform the '#{method}' method. #{permission}"
      end

      def set_token
        @token = Current.user.tokens.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        not_found_error('token')
      end

      def set_user_subscription
        @subscription = Current.user.subscriptions.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        not_found_error('subscription')
      end

      def decode_bearer_token
        @decoded_bearer_token = AuthenticationTokenService::Access::Decoder.call(bearer_token)[0]
      end

      def decode_client_token
        @decoded_client_token = QuicklinkService::Client::Decoder.call(request.headers['HTTP_CLIENT_TOKEN'])[0]
      end

      def decode_request_token
        @decoded_request_token = QuicklinkService::Request::Decoder.call(request.headers['HTTP_REQUEST_TOKEN'])[0]
      end

      def validate_active_job_id
        @job = Job.find(params[:id])
        removed_error('job') unless %w[listed unlisted].include?(@job.job_status) && @job.activity_status == 1
      rescue ActiveRecord::RecordNotFound
        not_found_error('job')
      end

      def validate_listed_job_id
        @job = Job.find(params[:id])
        removed_error('job') unless @job.job_status == 'listed' && @job.activity_status == 1
      rescue ActiveRecord::RecordNotFound
        not_found_error('job')
      end

      def validate_job_id
        @job = Job.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        not_found_error('job')
      end

      def validate_user_id
        @user = User.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        not_found_error('user')
      end

      def validate_notification_id
        @notification = Notification.find(params[:id])
        raise CustomExceptions::Unauthorized::Blocked if @notification.recipient.id.to_i != Current.user.id.to_i
      rescue ActiveRecord::RecordNotFound
        not_found_error('notification')
      end

      def bearer_token
        pattern = /^Bearer /
        header  = request.headers['Authorization'] # <= access and client tokens are stored in the Authorization header
        header.gsub(pattern, '') if header&.match(pattern)
      end
    end
  end
end
