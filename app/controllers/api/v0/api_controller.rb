# frozen_string_literal: true

class APIController < ApplicationController
  protect_from_forgery with: :null_session
end
