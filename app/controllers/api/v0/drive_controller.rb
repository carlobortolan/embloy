module Api
  module V0
    class DriveController < ApiController
      #before_action :verify_access_token
      def website_content
        begin
          if params[:page] == "b2b"
            content = WebsiteDataSource.page_b2b
          else
            content = WebsiteDataSource.page_b2b
          end
          p content
          render status: 200, json: { "content": content}

        end
      end

    end
  end
end
