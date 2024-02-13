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
        if token_blank?
          blank_error('token')
        else
          set_user_from_token
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
      # Deprecated method - replaced by set_current_user
      def verify_access_token
        token_blank? ? blank_error('token') : decode_access_token
      end

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

      private

      def token_blank?
        request.headers['HTTP_ACCESS_TOKEN'].nil? || request.headers['HTTP_ACCESS_TOKEN'].empty?
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
        @decoded_token = AuthenticationTokenService::Access::Decoder.call(request.headers['HTTP_ACCESS_TOKEN'])[0]
        begin
          Current.user = (@decoded_token['sub'].to_i.zero? ? nil : User.find(@decoded_token['sub'].to_i))
        rescue ActiveRecord::RecordNotFound
          not_found_error('user')
        end
      end

      def set_user_subscription
        @subscription = Current.user.subscriptions.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        not_found_error('subscription')
      end

      def decode_access_token
        @decoded_token = AuthenticationTokenService::Access::Decoder.call(request.headers['HTTP_ACCESS_TOKEN'])[0]
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
    end
  end
end
