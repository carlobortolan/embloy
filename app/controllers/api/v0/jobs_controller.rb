require_relative '../../../../lib/feed_generator.rb'
require 'net/http'
module Api
  module V0
    class JobsController < ApiController
      before_action :verify_access_token

      def create
        begin
          verified!(@decoded_token["typ"])
          job_params["status"] = 0
          @job = Job.new(job_params)
          @job.user_id = @decoded_token["sub"]

          job_types_file = File.read(Rails.root.join('app/helpers', 'job_types.json'))
          job_types = JSON.parse(job_types_file)
          job_type = @job.job_type
          @job.job_type_value = job_types[job_type]
          @job.job_status = 1

          if @job.save
            SpatialJobValue.update_job_value(@job)
            render status: 200, json: { "message": "Job created!" }
          else
            if @job.errors.details != false
              error = @job.errors.details.dup # necessary because @job.errors.details cant be modified manually
              error.each do |a,b|
                b.each_with_index do |e, i|
                  b[i] = flatted_first_element(e)
                end
              end
              if error[:job_type_value].present? && error[:job_type_value][0][:error] == "ERR_BLANK"
                error.delete('job_type_value') # in case that job_type_value is blank error is raised, delete it because it is against the documentation policy of only raising blank errors for required attributes (and job_type value is non)
                not_found_error('job_type')
                return 0
              else
                render status: 400, json: error
              end
            else
              render status: 400, json: @job.errors.details
            end
          end

        rescue ActionController::ParameterMissing
          blank_error('job')
        end
      end

      def update
        begin
          verified!(@decoded_token["typ"])
          return blank_error('id') if params[:id].nil? || params[:id].empty?
          return malformed_error('id') unless params[:id].to_i.class == Integer && params[:id].to_i > 0
          must_be_owner!(params[:id], @decoded_token["sub"])
          return removed_error('job') if @job.job_status == 0
          if @job.update(update_job_params)
            SpatialJobValue.update_job_value(@job)
            render status: 200, json: { "message": "Job updated!" }
          else
            render status: 400, json: @job.errors.details
          end

        rescue ActionController::ParameterMissing # just relevant for strong parameters
          blank_error('job')

        end

      end

      def destroy
        begin
          must_be_editor!(@decoded_token["sub"])
          #verified!(@decoded_token["typ"]) #jobs should be removed with job_status = 0 instead of being irreversibly deleted
          #must_be_owner!(params[:id], @decoded_token["sub"])
          return blank_error('id') if params[:id].nil? || params[:id].empty?
          return malformed_error('id') unless params[:id].to_i.class == Integer && params[:id].to_i > 0
          @job = Job.find(params[:id]) # no must_be_owner! call @job needs to be set manually
          @job.destroy!
          render status: 200, json: { "message": "Job deleted!" }
        rescue ActiveRecord::RecordNotFound
          not_found_error('job') # ok to be this specific because onöy editors can delete jobs
        end
      end

      # Creates feed based on current user's preferences (if available); if the current user is not verified yet or
      # isn't logged in, his feed consists of random jobs (limit 100)
      def feed
        begin
          # Check that user is verified
          # request.headers["HTTP_ACCESS_TOKEN"].nil? ? taboo! : @decoded_token = AuthenticationTokenService::Access::Decoder.call(request.headers["HTTP_ACCESS_TOKEN"])[0]
          verified!(@decoded_token["typ"])

          # Create slice to find possible jobs
          jobs = JobSlicer.slice(User.find(@decoded_token["sub"].to_i))

          # Call FG-API to rank jobs
          if !jobs.nil? && !jobs.empty?
            feed = call_feed(jobs)
            feed.nil? || feed.empty? ? render(status: 500, json: { "message": "Feed could not be generated!" }) : render(status: 200, json: { "feed": feed })
          else
            render status: 204, json: { "message": "No jobs found!" }
          end
        rescue CustomExceptions::Unauthorized::InsufficientRole
          render(status: 200, json: { "feed": Job.all.limit(100) })
        end
      end

      private

      # Method to communicate with the FG-API by sending a POST-request to tbd
      def call_feed(jobs)
        # url = URI.parse("https://embloy-fg-api.onrender.com/feed")
        url = URI.parse("http://localhost:8080/feed")
        if Current.user.nil? || Current.user.preferences.nil?
          request_body = "{\"slice\": #{jobs.to_json}}"
        else
          request_body = "{\"pref\": #{Current.user.preferences.to_json},\"slice\": #{jobs.to_json}}"
        end
        puts request_body
        http = Net::HTTP.new(url.host, url.port)
        # http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_PEER

        request = Net::HTTP::Post.new(url)
        request.basic_auth('FG', 'pw')
        request.body = request_body
        request["Content-Type"] = "application/json"

        response = http.request(request)

        JSON.parse(response.body)
      end

      def job_params
        # params.require(:job).permit(:title, :description, :content, :job_notifications, :start_slot, :notify, :status, :user_id, :longitude, :latitude, :job_type, :position, :currency, :salary, :key_skills, :duration, :job_type)

        # =================== API v0 ====================
        # ===============================================
        params.require(:job).permit(:title, :description, :start_slot, :user_id, :longitude, :latitude, :job_type, :position, :currency, :salary, :key_skills, :duration)
      end
      def update_job_params
        params.require(:job).permit(:title, :description, :start_slot, :user_id, :longitude, :latitude, :job_type, :status, :job_status, :position, :currency, :salary, :key_skills, :duration)
      end
      # mark_notifications_as_read is not implemented because i dont understand how it works
=begin
      def mark_notifications_as_read
        if Current.user
          notifications_to_mark_as_read = @job.notifications_as_job.where(recipient: Current.user)
          notifications_to_mark_as_read.update_all(read_at: Time.zone.now)
        end
      end
=end
    end
  end
end