# frozen_string_literal: true
module Api
  module V0
    class JobAssignmentController < ApiController
      before_action :verify_access_token
      before_action :verify_path_job_id, only: [:create]
      before_action :verify_path_user_id, only: [:create]

      def create
        begin
          # TODO: implement
        end
      end

    end
  end
end
