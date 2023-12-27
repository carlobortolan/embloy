# frozen_string_literal: true

module Api
  module V0
    # JobAssignmentController handles job assignment-related actions
    class JobAssignmentController < ApiController
      before_action :verify_path_job_id,
                    only: [:create]
      before_action :verify_path_user_id,
                    only: [:create]

      def create
        must_be_verified!(Current.user.id)
        # verify strong param input
        return blank_error('assignment') if assignment_params[:user_id].nil? || assignment_params[:user_id].blank?

        # verify user_id claim (the user that is assigned to a job)
        begin
          review_params[:user_id] =
            Integer(assignment_params[:user_id])
          raise ArgumentError unless review_params[:user_id].positive?

          User.find(review_params[:user_id])
        rescue ActiveRecord::RecordNotFound
          CustomExceptions::InvalidUser::Unknown
        rescue ArgumentError
          malformed_error('user_id')
        end

        #--------------------------------------

        # Verify whether Job existss
      end

      def assignment_params
        params.require(:assignment).permit(:user_id)
      end
    end
  end
end
