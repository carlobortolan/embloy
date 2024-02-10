# frozen_string_literal: true

require 'net/http'
module Api
  module V0
    # JobsController handles job-related actions
    class JobsController < ApiController
      before_action :verify_path_job_id,
                    only: %i[update destroy show]
      before_action :must_be_subscribed

      def create
        job = build_job
        job.assign_job_type_value
        # job.job_status = 1

        if job.save
          process_after_save(job)
          render status: 201, json: { message: 'Job created!' }
        else
          render status: 400, json: job.errors.details
        end
      rescue ActiveSupport::MessageVerifier::InvalidSignature
        malformed_error('image_url')
      rescue ActionController::ParameterMissing
        blank_error('job')
      end

      def update
        must_be_owner!(params[:id], Current.user.id)
        return removed_error('job') if @job.job_status.zero?

        if update_job_attributes
          process_after_save(@job)
          render status: 200, json: { message: 'Job updated!' }
        else
          render status: 400, json: @job.errors.details
        end
      rescue ActiveSupport::MessageVerifier::InvalidSignature
        malformed_error('image_url')
      rescue ActionController::ParameterMissing
        blank_error('job')
      end

      def destroy
        # TODO: @jh: Why use `must_be_editor!` and not `owner!`?
        # must_be_editor!(Current.user.id)
        must_be_owner!(params[:id], Current.user.id)
        # job = Job.find(params[:id]) # no must_be_owner! call @job needs to be set manually
        @job.destroy!
        render status: 200, json: { message: 'Job deleted!' }
      rescue ActiveRecord::RecordNotFound
        not_found_error('job') # ok to be this specific because only editors can delete jobs
      end

      # Creates feed based on current user's preferences (if available); if the current user is not verified yet or
      # isn't logged in, his feed consists of random jobs (limit 100)
      def feed
        redirect = validate_coordinates
        return redirect if redirect.is_a?(String)

        jobs, redirect = create_job_slice
        return redirect if redirect.is_a?(String)

        redirect = create_and_render_feed(jobs)
        redirect if redirect.is_a?(String)
      end

      # Returns jobs near given coordinates
      def map
        redirect = validate_coordinates
        return redirect if redirect.is_a?(String)

        lat, lng = fetch_user_coordinates

        jobs = JobSlicer.fetch_map(lat, lng)
        if jobs.empty?
          render(status: 204, json: { jobs: })
        else
          render(status: 200, json: "{\"jobs\": [#{Job.get_jsons_include_user(jobs)}]}")
        end
      end

      # Returns a specific job
      def show
        begin
          job = Job.find_by(job_id: params[:id])
        rescue ActiveRecord::RecordNotFound
          render(status: 404, json: { message: "Job with id #{params[:id]} does not exist!" }) and return
        end
        return access_denied_error('job') if (job.user_id != Current.user.id && job.status != 'public') || job.nil?

        render(status: 200, json: "{\"job\": #{Job.json_for(job)}}")
      end

      def find
        jobs = job_params[:query].presence ? search_jobs : Job.includes(image_url_attachment: :blob).includes([:rich_text_description]).all

        render status: 204, json: { message: 'No jobs found!' } and return if jobs.blank?

        jobs = filter_jobs_by_type(jobs)
        jobs = sort_jobs(jobs)
        render_jobs('jobs', jobs)
      end

      private

      def update_job_attributes
        @job.update(job_params)
      end

      def build_job
        job = Job.new(job_params)
        job.user_id = Current.user.id
        job
      end

      def process_after_save(job)
        SpatialJobValue.update_job_value(job)

        return unless job_params[:image_url].present?

        job.image_url.attach(job_params[:image_url])
      end

      def validate_coordinates
        lat, lng = [find_job_params[:latitude], find_job_params[:longitude]].map do |coordinate|
          return blank_error(coordinate) if coordinate.blank?

          begin
            Float(coordinate)
          rescue StandardError
            (return malformed_error(coordinate))
          end
        end

        return malformed_error('latitude') unless valid_latitude?(lat)

        malformed_error('longitude') unless valid_longitude?(lng)
      end

      def create_job_slice
        jobs = JobSlicer.slice(Current.user, 30_000, Float(params[:latitude]), Float(params[:longitude]))
        render(status: 204, json: { message: 'No jobs found!' }) and return if jobs.nil? || jobs.empty?

        jobs
      end

      def create_and_render_feed(jobs)
        if jobs.present?
          feed_ids = call_feed(jobs)
          if feed_ids.nil?
            render(status: 500, json: { message: 'Feed service is currently unavailable. Please try again later.' })
          else
            feed = feed_ids.map { |j_id| Job.find_by_job_id(j_id) }
            if feed.empty?
              render(status: 500, json: { message: 'Please try again later. If this error persists, we recommend to contact our support team' })
            else
              render_jobs('feed', feed)
            end
          end
        else
          render status: 204, json: { message: 'No jobs found!' }
        end
      end

      # Method to communicate with the FG-API by sending a POST-request
      def call_feed(jobs)
        url = URI.parse(ENV.fetch('FG_URL', 'https://embloy-fg-api.onrender.com/feed'))
        request = create_feed_request(jobs, url)
        http = Net::HTTP.new(url.host, url.port).tap do |http_instance|
          http_instance.use_ssl = true
          http_instance.verify_mode = OpenSSL::SSL::VERIFY_PEER
        end

        response = http.request(request) # This line is missing in your code

        process_response(response)
      end

      def create_feed_request(jobs, url)
        body = if Current.user&.preferences
                 "{\"pref\": #{Current.user.preferences.to_json}, \"slice\": [#{Job.jsons_for(jobs)}]}"
               else
                 "{\"slice\": [#{Job.jsons_for(jobs)}]}"
               end

        Net::HTTP::Post.new(url).tap do |request|
          request.basic_auth(ENV.fetch('FG_U', nil), ENV.fetch('FG_PW', nil))
          request.body = body
          request['Content-Type'] = 'application/json'
        end
      end

      def process_response(response)
        return unless response.code == '200'

        feed_json = JSON.parse(response.body)
        feed_json.map { |job_hash| job_hash['job_id'] }
      end

      def search_jobs
        query = "%#{ActiveRecord::Base.sanitize_sql_like(find_job_params[:query])}%"
        Job.includes(image_url_attachment: :blob)
           .includes([:rich_text_description])
           .where("status = 'public' AND " \
                  '(title ILIKE :query OR ' \
                  'description ILIKE :query OR ' \
                  'position ILIKE :query OR ' \
                  'job_type ILIKE :query OR ' \
                  'key_skills ILIKE :query OR ' \
                  'address ILIKE :query OR ' \
                  'city ILIKE :query OR ' \
                  'postal_code ILIKE :query OR ' \
                  "COALESCE(start_slot::text, '') ILIKE :query)", query:)
           .page(find_job_params[:page])
      end

      def filter_jobs_by_type(jobs)
        return jobs if !find_job_params[:job_type].present? || jobs.nil?

        jobs.where(job_type: find_job_params[:job_type])
      end

      def sort_jobs(jobs)
        return jobs if !find_job_params[:sort_by].present? || jobs.nil?

        sort_options = {
          'salary_asc' => { salary: :asc },
          'salary_desc' => { salary: :desc },
          'date_asc' => { created_at: :asc },
          'date_desc' => { created_at: :desc }
        }

        order = sort_options[find_job_params[:sort_by]]
        order ? jobs.order(order) : []
      end

      def render_jobs(tag, jobs)
        if jobs.present?
          render status: 200, json: "{\"#{tag}\": [#{Job.jsons_for(jobs.page(find_job_params[:page]).per(24))}]}"
        else
          render status: 204, json: { message: 'No jobs found!' }
        end
      end

      def fetch_user_coordinates
        if Current.user&.longitude && Current.user&.latitude
          [Current.user.latitude, Current.user.longitude]
        else
          [nil, nil]
        end
      end

      def valid_latitude?(lat)
        lat.abs <= 90.0
      end

      def valid_longitude?(lng)
        lng.abs <= 180.0
      end

      # mark_notifications_as_read is not implemented because i dont understand how it works
      #       def mark_notifications_as_read
      #         if Current.user
      #           notifications_to_mark_as_read = @job.notifications_as_job.where(recipient: Current.user)
      #           notifications_to_mark_as_read.update_all(read_at: Time.zone.now)
      #         end
      #       end

      def job_params
        params.except(:format).permit(:title, :description, :start_slot, :referrer_url, :longitude, :latitude, :job_type, :status, :image_url, :position, :currency, :salary, :key_skills, :duration,
                                      :job_notifications, :cv_required, allowed_cv_formats: [], application_options_attributes: [:id, :question, :question_type, :required, { options: [] }])
      end

      def find_job_params
        params.except(:format).permit(:query, :job_type, :sort_by, :page, :longitude, :latitude)
      end
    end
  end
end
