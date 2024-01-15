# frozen_string_literal: true

module Api
  module V0
    # SubscriptionsController handles static-resources-related actions
    class StaticController < ApiController
      skip_before_action :set_current_user, only: %i[redirect_to_docs]

      def redirect_to_docs
        redirect_to ENV.fetch('EMBLOY_DEVELOPERS_URL', 'https://github.com/embloy'), allow_other_host: true
      end
    end
  end
end
