module Api
  module V0
    class ApplicationsController < ApiController
      before_action :verify_access_token

      def show
        begin
            verified!(@decoded_token["typ"])
            return blank_error('job') if params[:id].nil? || params[:id].empty?
            return malformed_error('job') unless params[:id].to_i.class == Integer && params[:id].to_i > 0
            must_be_owner!(params[:id], @decoded_token["sub"])
            applications = @job.applications.find_by_sql("SELECT * FROM applications a WHERE a.job_id = #{@job.job_id}")
            if applications.empty?
              render status: 204, json: { "applications": applications }
            else
              render status: 200, json: { "applications": applications }
            end
        end
      end
=begin
      def show
        begin
          verified!(@decoded_token["typ"])
          must_be_owner!(params[:id], @decoded_token["sub"])
          applications = @job.applications.find_by_sql("SELECT * FROM applications a WHERE a.user_id = #{@decoded_token["sub"]} and a.job_id = #{@job.job_id}")
          if applications.empty?
            render status: 204, json: { "applications": applications }
          else
            render status: 200, json: { "applications": applications }
          end
        end
      end
=end
      def create
          begin
            verified!(@decoded_token["typ"])
            job = Job.find(params[:id])
            application = Application.create!(
              user_id: @decoded_token["sub"],
              job_id: job.job_id,
              application_text: "This application was submitted through the v.0 Embloy API",
              applied_at: Time.now,
              updated_at: Time.now,
              response: "No response yet..."
            )
            application.user = User.find(@decoded_token["sub"])
            application.save!
            render status: 200, json: { "message": "Application submitted!" }

          rescue ActiveRecord::RecordNotUnique
            unnecessary_error('application')

          rescue ActiveRecord::RecordNotFound
            if params[:id].nil?
              blank_error('job')
            else
              malformed_error('job')
            end

          rescue ActiveRecord::RecordInvalid
            malformed_error('application')

        end
      end

      # destroy throws ActiveJob::SerializationError => until resolved there wont be application delete functionality via api
=begin
      def destroy
        if request.headers["HTTP_ACCESS_TOKEN"].nil?
          render status: 400, json: { "access_token": [
            {
              "error": "ERR_BLANK",
              "description": "Attribute can't be blank"
            }
          ]
          }
        else
          begin
            decoded_token = AuthenticationTokenService::Access::Decoder.call(request.headers["HTTP_ACCESS_TOKEN"])[0]
            verified!(decoded_token["typ"])
            job = Job.find(params[:id])
            application = job.applications.find(decoded_token["sub"])



            application = Application.find_by_sql("SELECT * FROM applications a WHERE a.user_id = #{decoded_token["sub"]} and a.job_id = #{params[:id]}")[0]
            application.destroy!




            render status: 200, json: { "message": "Application deleted!" }

          end
        end
        end
=end

      # Todo: Wait for .accept in application.rb implementation and implement methods accordingly

      def accept
        end
=begin

      def reject
        @job = Job.find(params[:job_id])
        if require_user_be_owner!
          # @application_service.reject(params[:job_id].to_i, params[:application_id].to_i, "REJECTED")
          redirect_to job_applications_path(params[:job_id]), status: :see_other, notice: 'Application has been rejected'
        end
      end

      def reject_all
        @job = Job.find(params[:job_id])
        if require_user_be_owner!
          # @application_service.reject_all(params[:job_id].to_i, "REJECTED")
          redirect_to job_path(@job), status: :see_other, notice: 'All Applications have been rejected'
        end
      end

      private

      def set_job
        @job = Job.find(params[:job_id])
      end
=end

    end
  end
end
