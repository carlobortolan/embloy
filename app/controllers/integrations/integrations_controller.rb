# frozen_string_literal: true
module Integrations
  # IntegrationsController handles Integration-related actions and verifications
  class IntegrationsController < ApplicationController
    include JobParser
    def register_ats_secret
      # TODO: Super-method to save api key or access token for current user (e.g., https://api.embloy.com/integrations/:ats_provider/register)
    end
  end
end
