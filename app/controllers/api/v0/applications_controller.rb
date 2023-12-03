module Api
  module V0
    class ApplicationsController < ApiController
      before_action :verify_path_job_id

      def show
        begin
          verified!(@decoded_token["typ"])
          must_be_owner!(params[:id], Current.user.id)
          applications = @job.applications.find_by_sql("SELECT * FROM applications a WHERE a.job_id = #{@job.job_id}")
          if applications.empty?
            render status: 204, json: { "applications": applications }
          else
            render status: 200, json: { "applications": applications }
          end
        end
      end

      def show_single
        begin
          verified!(@decoded_token["typ"])
          set_at_job(params[:id])
          application = @job.applications.find_by_sql("SELECT * FROM applications a WHERE a.job_id = #{@job.job_id} AND a.user_id = #{Current.user.id}")

          if application.empty? || application.nil?
            render status: 204, json: { "application": application }
          else
            render status: 200, json: { "application": application }
          end
        end
      end

      # TODO: Improve in future versions
      def create
        verified!(@decoded_token["typ"])
        job = Job.find(params[:id])

        if job.cv_required
          if params[:application_attachment].present?
            application_attachment = ""
            begin
              application_attachment = ApplicationAttachment.create!(
                user_id: Current.user.id,
                job_id: params[:id].to_i
              )

              application_attachment.cv.attach(params[:application_attachment])
              application_attachment.save!

              application = Application.create!(
                user_id: Current.user.id,
                job_id: job.job_id,
                application_text: params[:application_text],
                application_documents: "empty",
                created_at: Time.now,
                updated_at: Time.now,
                response: "No response yet ..."
              )

              application.user = Current.user
              application.job = job
              render status: 200, json: { "message": "Application submitted!" }

            rescue ActiveRecord::RecordInvalid
              if application_attachment != ""
                application_attachment.destroy
              end
              render status: 400, json: { "message": "Application could not be submitted due to invalid file attachment" }
            end
          else
            malformed_error('application attachment')
          end
        else
          application = Application.create!(
            user_id: Current.user.id,
            job_id: job.job_id,
            application_text: params[:application_text],
            created_at: Time.now,
            updated_at: Time.now,
            response: "null"
          )
          begin
            application.user = Current.user
          rescue ActiveRecord::RecordNotFound
            raise CustomExceptions::InvalidUser::Unknown
          end

          if application.save!
            render status: 200, json: { "message": "Application submitted!" }
          else
            malformed_error('application')
          end
        end
      rescue ActiveRecord::RecordNotUnique
        unnecessary_error('application')

      rescue ActiveRecord::RecordNotFound
        raise CustomExceptions::InvalidJob::Unknown
      end

      def accept
        begin
          verified!(@decoded_token["typ"])
          must_be_owner!(params[:id], Current.user.id)
          job = Job.find(params[:id])
          application = job.applications.where(user_id: params[:application_id]).first

          if application.nil?
            render status: 404, json: { "message": "Not found." }
            return
          end

          if application.status != "1"
            if application_params[:response]
              application.accept(application_params[:response])
            else
              application.accept("ACCEPTED")
            end
          else
            render status: 400, json: { "message": "Already accepted." }
            return
          end

          render status: 200, json: { "message": "Application successfully accepted." }
        rescue ActiveRecord::RecordNotFound
          render status: 404, json: { "message": "Not found." }
        end
      end

      def reject
        begin
          verified!(@decoded_token["typ"])
          must_be_owner!(params[:id], Current.user.id)
          job = Job.find(params[:id])
          application = job.applications.where(user_id: params[:application_id]).first

          if application.nil?
            render status: 404, json: { "message": "Not found." }
            return
          end
          puts "APPLICATION STATUS = #{application.status}"
          if application.status != "-1"
            if application_params[:response]
              application.reject(application_params[:response])
            else
              application.reject("REJECTED")
            end
          else
            render status: 400, json: { "message": "Already rejected." }
            return
          end

          render status: 200, json: { "message": "Application successfully rejected." }
        rescue ActiveRecord::RecordNotFound
          render status: 404, json: { "message": "Not found." }
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
            application = job.applications.find(Current.user.id)



            application = Application.find_by_sql("SELECT * FROM applications a WHERE a.user_id = #{Current.user.id} and a.job_id = #{params[:id]}")[0]
            application.destroy!




            render status: 200, json: { "message": "Application deleted!" }

          end
        end
        end
=end

      # Todo: Wait for .accept in application.rb implementation and implement methods accordingly

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

      def application_params
        params.permit(:application).permit(:user_id, :application_text, :application_documents, :response, :cv)
      end

      def application_params2
        params.permit(:user_id, :application_text, :application_documents, :response, :cv)
      end

    end
  end
end
