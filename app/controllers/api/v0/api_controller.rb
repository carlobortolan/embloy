# frozen_string_literal: true
require_relative '../../../service/api_exception_handler.rb'
module Api
  module V0
    class ApiController < ApplicationController
      include ApiExceptionHandler
      protect_from_forgery with: :null_session

      def verify_access_token
        (request.headers["HTTP_ACCESS_TOKEN"].nil? || request.headers["HTTP_ACCESS_TOKEN"].empty?) ? blank_error('token') : @decoded_token = AuthenticationTokenService::Access::Decoder.call(request.headers["HTTP_ACCESS_TOKEN"])[0]
      end

      def verify_path_job_id
        return blank_error('job') if params[:id].nil? || params[:id].empty? || params[:id].blank? || params[:id] == ":id"
        begin
          params[:id] = Integer(params[:id])
          raise ArgumentError unless params[:id] > 0
        rescue ArgumentError
          return malformed_error('job')
        end
      end

    end
  end
end