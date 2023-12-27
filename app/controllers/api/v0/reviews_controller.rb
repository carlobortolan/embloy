# frozen_string_literal: true

module Api
  module V0
    # ReviewsController handles review-related actions
    class ReviewsController < ApiController
      before_action :verify_path_user_id,
                    only: %i[create update]

      def create
        must_be_verified!
        verify_review_params
        verify_job_id
        verify_rating
        must_be_verified_id_and_job
        verify_review_existence
        make_review
      rescue ActionController::ParameterMissing
        blank_error('review')
      end

      def update
        must_be_verified!
        verify_review_params
        verify_job_id
        verify_rating unless review_params[:rating].nil?
        verify_review_existence
        update_review
      rescue ActionController::ParameterMissing
        blank_error('review')
      end

      def destroy
        must_be_verified!
        review = Review.find(params[:id])
        verify_owner(review)
        review.destroy!
        render status: 200,
               json: { "message": 'Review deleted!' }
      rescue ActionController::ParameterMissing
        blank_error('review')
      rescue ActiveRecord::RecordNotFound
        handle_record_not_found
      rescue ActiveRecord::StatementInvalid
        malformed_error('review')
      end

      private

      def verify_review_params
        blank_error('job_id') if review_params[:job_id].nil? || review_params[:job_id].blank?
      end

      def verify_job_id
        review_params[:job_id] = Integer(review_params[:job_id])
        raise ArgumentError unless review_params[:job_id].positive?

        Job.find(review_params[:job_id])
      rescue ActiveRecord::RecordNotFound
        raise CustomExceptions::InvalidJob::Unknown
      rescue ArgumentError
        malformed_error('job_id')
      end

      def verify_rating
        review_params[:rating] = Integer(review_params[:rating])
        valid_ratings = [0, 1, 2, 3, 4, 5]
        raise ArgumentError unless valid_ratings.include?(review_params[:rating])
      rescue ArgumentError
        malformed_error('rating')
      end

      def must_be_verified_id_and_job
        return biased_error('user') if Current.user.id == params[:id]

        job = Job.find(review_params[:job_id])
        verify_application(job)
      end

      def verify_application(job)
        if Current.user.id == job.user_id # employer rates employee
          verify_application_for_employer(job)
        elsif params[:id] == job.user_id # employee rates employer
          verify_application_for_employee(job)
        else
          # only an employee can rate its employer based on a given job and vice versa
          access_denied_error('user')
        end
      end

      def verify_application_for_employer(job)
        application = job.applications.where('job_id = ? AND user_id = ?', job.job_id, params[:id])
        access_denied_error('user') if application.nil? || application.empty? || application[0].status.to_i != 1
      end

      def verify_application_for_employee(job)
        application = job.applications.find_by_sql("SELECT * FROM applications a WHERE a.job_id = #{job.job_id} AND a.user_id = #{Current.user.id}")
        access_denied_error('user') if application.nil? || application.empty? || application[0].status.to_i != 1
      end

      def verify_review_existence
        unnecessary_error('review') if Review.all.where(user_id: Current.user.id, subject: params[:id], job_id: review_params[:job_id]).present?
      end

      def make_review
        review = Review.new(review_params)
        review.subject = params[:id]
        review.user_id = Current.user.id
        review.created_by = Current.user.id # TODO: migrate to drop column
        review.save!
        render status: 200, json: { "message": 'Review submitted!' }
      end

      def update_review
        review = Review.all.where(user_id: Current.user.id, subject: params[:id], job_id: review_params[:job_id])
        return not_found_error('review') unless review.present?

        if review.update(review_params)
          render status: 200, json: { "message": 'Review updated!' }
        else
          render status: 400, json: review.errors.details
        end
      end

      def verify_owner(review)
        review.created_by.to_i == Current.user.id ? true : raise(CustomExceptions::Unauthorized::NotOwner)
      end

      def review_params
        params.require(:review).permit(:rating, :message, :job_id)
      end
    end
  end
end
