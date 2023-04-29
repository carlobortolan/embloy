module Api
  module V0

    class ReviewsController < ApiController
      before_action :verify_access_token
      before_action :verify_path_user_id, only: [:create, :update]

      def create
        # todo: test review update, review delete method, adapt doc
        begin
          must_be_verified!(@decoded_token["sub"])
          # verify strong param input
          if (review_params[:rating].nil? || review_params[:rating].blank?) && review_params[:job_id].present?
            return blank_error('rating')
          elsif (review_params[:job_id].nil? || review_params[:job_id].blank?) && review_params[:rating].present?
            return blank_error('job_id')
          elsif (review_params[:job_id].nil? || review_params[:job_id].blank?) && (review_params[:rating].nil? || review_params[:rating].blank?)
            render status: 400, json: { "rating" => [{ error: 'ERR_BLANK', description: 'Attribute can\'t be blank' }], "job_id" => [{ error: 'ERR_BLANK', description: 'Attribute can\'t be blank' }] }
            return -1
          end

          #--------------------------------------

          # verify job_id claim
          begin
            review_params[:job_id] = Integer(review_params[:job_id])
            raise ArgumentError unless review_params[:job_id] > 0
            job = Job.find(review_params[:job_id])
          rescue ActiveRecord::RecordNotFound
            raise CustomExceptions::InvalidJob::Unknown
          rescue ArgumentError
            return malformed_error('job_id')
          end

          #--------------------------------------

          # verify rating claim
          begin
            # this construction is necessary to account that a string parsed to an integer is 0 and we want to allow 0 as input
            review_params[:rating] = Integer(review_params[:rating])
            raise ArgumentError unless review_params[:rating] == 0 || review_params[:rating] == 1 || review_params[:rating] == 2 || review_params[:rating] == 3 || review_params[:rating] == 4 || review_params[:rating] == 5
          rescue ArgumentError
            return malformed_error('rating')
          end

          #--------------------------------------

          # verify user_id path input & user_id from job
          return biased_error('user') if @decoded_token["sub"] == params[:id]
          if @decoded_token["sub"] == job.user_id # employer rates employee
            application = job.applications.find_by_sql("SELECT * FROM applications a WHERE a.job_id = #{job.job_id} AND a.user_id = #{params[:id]}")
            return access_denied_error('user') if application.nil? || application.empty? || application[0].status.to_i != 1 # only reviews between employers and emplyees are allowed #todo: add way to know who is an actual employee
          elsif params[:id] == job.user_id # employee rates employer
            application = job.applications.find_by_sql("SELECT * FROM applications a WHERE a.job_id = #{job.job_id} AND a.user_id = #{@decoded_token["sub"]}")
            return access_denied_error('user') if application.nil? || application.empty? || application[0].status.to_i != 1 # only reviews between employers and emplyees are allowed #todo: add way to know who is an actual employee
          else
            # only an employee can rate its employer based on a given job and vice versa
            return access_denied_error('user')
          end

          #--------------------------------------

          # verify whether this specific review already exists
          return unnecessary_error('review') if Review.all.where(:user_id => @decoded_token["sub"], :subject => params[:id], :job_id => review_params[:job_id]).present?

          # make review
          review = Review.new(review_params)
          review.subject = params[:id]
          review.user_id = @decoded_token["sub"]
          review.created_by = @decoded_token["sub"] # todo migrate to drop column
          review.save!
          render status: 200, json: { "message": "Review submitted!" }
        rescue ActionController::ParameterMissing # full review_params strong parameter missing
          return blank_error('review')
        end
      end

      def update
        begin
          must_be_verified!(@decoded_token["sub"])
          # verify strong param input
          return blank_error('job_id') if review_params[:job_id].nil? || review_params[:job_id].blank?

          #--------------------------------------

          # verify job_id claim
          begin
            review_params[:job_id] = Integer(review_params[:job_id])
            raise ArgumentError unless review_params[:job_id] > 0
            job = Job.find(review_params[:job_id])
          rescue ActiveRecord::RecordNotFound
            raise CustomExceptions::InvalidJob::Unknown
          rescue ArgumentError
            return malformed_error('job_id')
          end

          #--------------------------------------

          # verify rating claim
          unless review_params[:rating].nil?
            begin
              # this construction is necessary to account that a string parsed to an integer is 0 and we want to allow 0 as input
              review_params[:rating] = Integer(review_params[:rating])
              raise ArgumentError unless review_params[:rating] == 0 || review_params[:rating] == 1 || review_params[:rating] == 2 || review_params[:rating] == 3 || review_params[:rating] == 4 || review_params[:rating] == 5
            rescue ArgumentError
              return malformed_error('rating')
            end
          end

          #--------------------------------------

          # verify whether this specific review really exists
          review = Review.all.where(:user_id => @decoded_token["sub"], :subject => params[:id], :job_id => review_params[:job_id])
          return not_found_error('review') unless review.present?

          #--------------------------------------

          if review.update(review_params)
            render status: 200, json: { "message": "Review updated!" }
          else
            render status: 400, json: review.errors.details
          end

        rescue ActionController::ParameterMissing # full review_params strong parameter missing
          return blank_error('review')

        end

      end

      def destroy

        begin
          verified!(@decoded_token["typ"])
          review = Review.find(params[:id])

          # TODO: Replace with general must_be_owner! method (if it then exist)
          ###############################################################################################################################
          review.created_by.to_i == User.find(@decoded_token["sub"].to_i).id ? true : raise(CustomExceptions::Unauthorized::NotOwner) #
          ###############################################################################################################################

          review.destroy!
          render status: 200, json: { "message": "Review deleted!" }

        rescue ActionController::ParameterMissing
          blank_error('review')
        rescue ActiveRecord::RecordNotFound
          if params[:id].nil?
            blank_error('review')
          else
            malformed_error('review')
          end
        rescue ActiveRecord::StatementInvalid
          malformed_error('review')

        end
      end

      private

      def review_params
        params.require(:review).permit(:rating, :message, :job_id)
      end

    end
  end
end