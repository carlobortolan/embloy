# frozen_string_literal: true
module Api
  module V0
    class ApiController < ApplicationController
      protect_from_forgery with: :null_session
    end
  end
end