# frozen_string_literal: true
module Api
  module V0
    class JobAssignmentController < ApiController
      before_action :verify_path_job_id, only: [:create]
      before_action :verify_path_user_id, only: [:create]

      def create
        begin
          must_be_verified!(Current.user.id)
          # verify strong param input
          if (assignment_params[:user_id].nil? || assignment_params[:user_id].blank?)
            return blank_error('assignment')
          end

          # verify user_id claim (the user that is assigned to a job)
          begin
            review_params[:user_id] = Integer(assignment_params[:user_id])
            raise ArgumentError unless review_params[:user_id] > 0
            user = User.find(review_params[:user_id])
          rescue ActiveRecord::RecordNotFound
            return CustomExceptions::InvalidUser::Unknown
          rescue ArgumentError
            return malformed_error('user_id')
          end

          #--------------------------------------

          # Verify whether Job existss
        end
      end

      def assignment_params
        params.require(:assignment).permit(:user_id)
      end

    end
  end
end
