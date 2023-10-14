require_relative '../../../../lib/feed_generator.rb'
require 'net/http'
module Api
  module V0
    class JobsController < ApiController
      before_action :verify_access_token
      before_action :verify_path_job_id, only: [:update, :destroy, :show]

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
            #SpatialJobValue.update_job_value(@job)
            # Attach image file to job-object

            @job.image_url.attach(params[:image_url]) if params[:image_url]
            render status: 200, json: { "message": "Job created!" }
          else
            if @job.errors.details != false
              error = @job.errors.details.dup # necessary because @job.errors.details cant be modified manually
              error.each do |a, b|
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
          must_be_owner!(params[:id], @decoded_token["sub"])
          return removed_error('job') if @job.job_status == 0 # TODO @jh: Set default job_status = 1 / make sure that job can be set to (de-)activated by owner
          if @job.update(update_job_params)
            SpatialJobValue.update_job_value(@job)
            # Attach image file to job-object
            @job.image_url.attach(params[:image_url]) if params[:image_url]
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
          # TODO: @jh: Why use `must_be_editor!` and not `owner!`?
          must_be_editor!(@decoded_token["sub"])
          # verified!(@decoded_token["typ"]) #jobs should be removed with job_status = 0 instead of being irreversibly deleted
          # must_be_owner!(params[:id], @decoded_token["sub"])
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
          if (params[:latitude].nil? || params[:latitude].blank?) && (params[:longitude].nil? || params[:longitude].blank?)
            render status: 400, json: { "latitude" => [{ error: 'ERR_BLANK', description: 'Attribute can\'t be blank' }], "longitude" => [{ error: 'ERR_BLANK', description: 'Attribute can\'t be blank' }] }
            return -1
          end
          return blank_error('latitude') if params[:latitude].nil? || params[:latitude].blank?
          return blank_error('longitude') if params[:longitude].nil? || params[:longitude].blank?
          begin
            params[:latitude] = Float(params[:latitude])
          rescue ArgumentError
            return malformed_error('latitude')
          end
          begin
            params[:longitude] = Float(params[:longitude])
          rescue ArgumentError
            return malformed_error('longitude')
          end
          # Create slice to find possible jobs
          jobs = JobSlicer.slice(User.find(@decoded_token["sub"].to_i), 30000, params[:latitude], params[:longitude])
          # Call FG-API to rank jobs
          if !jobs.nil? && !jobs.empty?
            #            feed = call_feed(jobs)
            # feed.nil? || feed.empty? ? render(status: 500, json: { "message": "Please try again later. If this error persists, we recommend to contact our support team" }) : render(status: 200, json: { "feed": feed })

            feed = []
            call_feed(jobs).each do |j_id|
              feed << Job.find_by_job_id(j_id)
            end
            feed.nil? || feed.empty? ? render(status: 500, json: { "message": "Please try again later. If this error persists, we recommend to contact our support team" }) : render(status: 200, json: "{\"feed\": [#{Job.get_jsons(feed)}]}")

          else
            render status: 204, json: { "message": "No jobs found!" } # message will not show with 204, just for maintainability
          end
        end
      end

      # Returns jobs near given coordinates
      def map
        lat = params[:latitude]
        lng = params[:longitude]

        return blank_error('latitude') if lat.nil? || lat.blank?
        return blank_error('longitude') if lng.nil? || lng.blank?
        begin
          lat = Float(lat)
        rescue ArgumentError
          return malformed_error('latitude')
        end
        begin
          lng = Float(lng)
        rescue ArgumentError
          return malformed_error('longitude')
        end

        user = User.find(@decoded_token["sub"].to_i)
        if !user.nil? && !user.longitude.nil? && !user.latitude.nil?
          lat = user.latitude
          lng = user.longitude
        end
        jobs = JobSlicer.fetch_map(lat, lng)
        # jobs.empty? ? render(status: 204, json: { "jobs": jobs }) : render(status: 200, json: "jobs: #{jobs.to_json(except: [:image_url])}")
        jobs.empty? ? render(status: 204, json: { "jobs": jobs }) : render(status: 200, json: "{\"jobs\": [#{Job.get_jsons_include_user(jobs)}]}")
      end

      # Returns a specific job
      def show
        begin
          job = Job.find(params[:id])
        rescue ActiveRecord::RecordNotFound
          render(status: 404, json: { "message": "Job with id #{params[:id]} does not exist!" })
          return
        end
        if job.nil?
          render(status: 204, json: { "job": job })
        else
          render(status: 200, json: "{\"job\": #{Job.get_json(job)}}")
        end
      end

      def find
        jobs = Job.includes(image_url_attachment: :blob).includes([:rich_text_description]).where("title ILIKE :query OR description ILIKE :query OR position ILIKE :query OR job_type ILIKE :query OR key_skills ILIKE :query OR address ILIKE :query OR city ILIKE :query OR postal_code ILIKE :query OR start_slot::text ILIKE :query", query: "%#{params[:query]}%")
                  .page(params[:page])

        if jobs.nil? || jobs.empty?
          jobs = Job.includes(image_url_attachment: :blob).includes([:rich_text_description]).all
        end

        unless params[:job_type].nil? || params[:job_type].blank?
          jobs = jobs.includes(image_url_attachment: :blob).includes([:rich_text_description]).where(job_type: params[:job_type])
        end

        case params[:sort_by]
        when "salary_asc"
          jobs = jobs.includes(image_url_attachment: :blob).includes([:rich_text_description]).order(salary: :asc)
        when "salary_desc"
          jobs = jobs.includes(image_url_attachment: :blob).includes([:rich_text_description]).order(salary: :desc)
        when "date_asc"
          jobs = jobs.includes(image_url_attachment: :blob).includes([:rich_text_description]).order(created_at: :asc)
        when "date_desc"
          jobs = jobs.includes(image_url_attachment: :blob).includes([:rich_text_description]).order(created_at: :desc)
        end

        if !jobs.nil? && !jobs.empty?
          render(status: 200, json: "{\"jobs\": [#{Job.get_jsons(jobs.page(params[:page]).per(24))}]}")
        else
          render status: 204, json: { "message": "No jobs found!" } # message will not show with 204, just for maintainability
        end
      end

      private

      # Method to communicate with the FG-API by sending a POST-request to tbd
      def call_feed(jobs)
        url = URI.parse("https://embloy-fg-api.onrender.com/feed")
        # url = URI.parse("http://localhost:8080/feed")
        if !Current.user.nil? && !Current.user.preferences.nil?
          request_body = "{\"pref\": #{Current.user.preferences.to_json}, \"slice\": [#{Job.get_jsons(jobs)}]}"
        else
          request_body = "{\"slice\": [#{Job.get_jsons(jobs)}]}"
        end
        http = Net::HTTP.new(url.host, url.port)
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_PEER

        request = Net::HTTP::Post.new(url)
        request.basic_auth('FG', 'pw')
        request.body = request_body
        request["Content-Type"] = "application/json"
        response = http.request(request)
        if response.code == '200'
          feed_json = JSON.parse(response.body)
          res = []
          feed_json.each do |job_hash|
            # puts job_hash["job_id"]
            res << job_hash["job_id"]
            # @jobs << Job.new(job_hash)
          end
          res
        end
      end

      def job_params
        # =================== API v0 ====================
        # ===============================================
        # params.require(:job).permit(:title, :description, :start_slot, :user_id, :longitude, :latitude, :job_type, :position, :currency, :salary, :key_skills, :duration)
        # Updated params to work with postman form-data
        params.permit(:title, :description, :start_slot, :user_id, :longitude, :latitude, :job_type, :position, :currency, :salary, :key_skills, :duration)
      end

      def update_job_params
        # params.require(:job).permit(:title, :description, :start_slot, :user_id, :longitude, :latitude, :job_type, :status, :job_status, :position, :currency, :salary, :key_skills, :duration)
        # Updated params to work with postman form-data
        params.permit(:title, :description, :start_slot, :user_id, :longitude, :latitude, :job_type, :status, :job_status, :position, :currency, :salary, :key_skills, :duration)
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