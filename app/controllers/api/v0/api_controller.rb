# frozen_string_literal: true
require_relative 'api_exception_handler.rb'
module Api
  module V0
    class ApiController < ApplicationController
      include ApiExceptionHandler
      protect_from_forgery with: :null_session

      def verify_access_token
        p "WLAN"
        request.headers["HTTP_ACCESS_TOKEN"].nil? ? blank_error('token') : @decoded_token = AuthenticationTokenService::Access::Decoder.call(request.headers["HTTP_ACCESS_TOKEN"])[0]
      end

    end
  end
end