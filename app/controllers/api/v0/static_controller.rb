# frozen_string_literal: true

module Api
  module V0
    # SubscriptionsController handles static-resources-related actions
    class StaticController < ApiController
      skip_before_action :set_current_user, only: %i[redirect_to_docs show_coverage]

      def redirect_to_docs
        redirect_to ENV.fetch('EMBLOY_DEVELOPERS_URL', 'https://github.com/embloy'), allow_other_host: true
      end

      def show_coverage
        coverage_path = Rails.root.join('coverage', params[:path] || '')
        if File.directory?(coverage_path)
          render file: File.join(coverage_path, 'index.html')
        else
          mime_type = Mime::Type.lookup_by_extension(File.extname(coverage_path).delete('.'))
          send_file coverage_path, type: mime_type
        end
      end
    end
  end
end
