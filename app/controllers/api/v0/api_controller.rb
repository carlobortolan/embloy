# frozen_string_literal: true

#########################################################
#################### API CONTROLLER #####################
#########################################################
require_relative '../../../service/api_exception_handler.rb'
module Api
  module V0
    class ApiController < ApplicationController
      include ApiExceptionHandler
      protect_from_forgery with: :null_session

      # Ignore Web-App before actions
      skip_before_action :auth_prototype

      # ============== API BEFORE ACTIONS ================
      before_action :set_current_user
      before_action :require_user_not_blacklisted!, if: Current.user

      # ============== API CONTROLLER HELPERS ================
      # Set current user of the API to the user found in the access_token
      # Set current user to nil if no token is provided
      def set_current_user
        if request.headers["HTTP_ACCESS_TOKEN"].nil? || request.headers["HTTP_ACCESS_TOKEN"].empty?
          blank_error('token')
        else
          @decoded_token = AuthenticationTokenService::Access::Decoder.call(request.headers["HTTP_ACCESS_TOKEN"])[0]
          begin
            @decoded_token["sub"].to_i == 0 ? Current.user = nil : Current.user = User.find(@decoded_token["sub"].to_i)
          rescue ActiveRecord::RecordNotFound
            not_found_error('user')
          end
        end
      end

      # Set queried subscription to @subscription to avoid code duplication
      def set_subscription
        unless Current.user.nil?
          verified!(@decoded_token["typ"])
          begin
            @subscription = Current.user.subscriptions.find(params[:id])
          rescue ActiveRecord::RecordNotFound
            not_found_error('subscription')
          end
        end
      end

      # ============== API TOKEN VERIFICATIOn ================
      # Deprecated method - replaced by set_current_user
      def verify_access_token
        (request.headers["HTTP_ACCESS_TOKEN"].nil? || request.headers["HTTP_ACCESS_TOKEN"].empty?) ? blank_error('token') : @decoded_token = AuthenticationTokenService::Access::Decoder.call(request.headers["HTTP_ACCESS_TOKEN"])[0]
      end

      def verify_client_token
        (request.headers["HTTP_CLIENT_TOKEN"].nil? || request.headers["HTTP_CLIENT_TOKEN"].empty?) ? blank_error('client token') : @decoded_client_token = QuicklinkService::Client::Decoder.call(request.headers["HTTP_CLIENT_TOKEN"])[0]
      end

      def verify_request_token
        (request.headers["HTTP_REQUEST_TOKEN"].nil? || request.headers["HTTP_REQUEST_TOKEN"].empty?) ? blank_error('request token') : @decoded_request_token = QuicklinkService::Request::Decoder.call(request.headers["HTTP_REQUEST_TOKEN"])[0]
      end

      # ============== API PATH VERIFICATIOn ================
      def verify_path_job_id
        return blank_error('job') if params[:id].nil? || params[:id].empty? || params[:id].blank? || params[:id] == ":id"
        begin
          params[:id] = Integer(params[:id])
          raise ArgumentError unless params[:id] > 0
        rescue ArgumentError
          return malformed_error('job')
        end
      end

      def verify_path_user_id
        return blank_error('user') if params[:id].nil? || params[:id].empty? || params[:id].blank? || params[:id] == ":id"
        begin
          params[:id] = Integer(params[:id])
          raise ArgumentError unless params[:id] > 0
          return User.find(params[:id])
        rescue ActiveRecord::RecordNotFound
          return not_found_error('user')
        rescue ArgumentError
          return malformed_error('user')
        end
      end
    end
  end
end