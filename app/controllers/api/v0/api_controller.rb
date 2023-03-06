# frozen_string_literal: true
require_relative './api_exception_handler.rb'
module Api
  module V0
    class ApiController < ApplicationController
      include ApiExceptionHandler
      protect_from_forgery with: :null_session
    end
  end
end