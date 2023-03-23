require_relative '../../lib/feed_generator.rb'

class JobsController < ApplicationController
  before_action :require_user_logged_in, except: %w[index show find parse_inputs]
  layout 'job_applic_layout', :only => "edit"

  # Creates feed based on current user's preferences (if available); if the current user is not verified yet or
  # isn't logged in, his feed consists of random jobs (limit 100)
  def index
    # Create slice to find possible jobs
    jobs = JobSlicer.slice(Current.user.nil? ? nil : Current.user)

    # Call FG-API to rank jobs
    if !jobs.nil? && !jobs.empty?
      @jobs = call_feed(jobs)
    else
      render status: 204, json: { "message": "No jobs found!" }
    end
  end

  def show
    @job = Job.find(params[:id])
    @owner = owner
    if Current.user
      @application = Application.find_by(user_id: Current.user.id, job_id: params[:id])
      mark_notifications_as_read
    end
  end

  def new
    @job = Job.new
    @categories_list = JSON.parse(File.read(Rails.root.join('app/helpers', 'job_types.json'))).keys
  end

  def create
    @job = Job.new(job_params)
    @job.user_id = Current.user.id

    job_types_file = File.read(Rails.root.join('app/helpers', 'job_types.json'))
    job_types = JSON.parse(job_types_file)
    job_type = @job.job_type
    @job.job_type_value = job_types[job_type]

    # @job.location_id = job_params[:location_id]
    if @job.save
      SpatialJobValue.update_job_value(@job)
      redirect_to @job, notice: "Created new job"
    else
      render :new, status: :unprocessable_entity, alert: "Job has not been created"
    end
  end

  def edit
    @job = Job.find(params[:id])
    @categories_list = JSON.parse(File.read(Rails.root.join('app/helpers', 'job_types.json'))).keys
    require_user_be_owner
  end

  def update
    @job = Job.find(params[:id])
    require_user_be_owner
    if @job.update(job_params)
      SpatialJobValue.update_job_value(@job)
      redirect_to @job
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @job = Job.find(params[:id])
    require_user_be_owner
    @job.destroy
    redirect_to own_jobs_path, status: :see_other, notice: "Job successfully deleted."
  end

  def findtest
    Job.ms_reindex!
    @jobs = Job.ms_search(params[:query])
    puts "RES = #{Job.ms_search(params[:query])}"
  end

  def find
    begin
      index = client.index('Job')
      #index.update_sortable_attributes(["created_at", "salary"])
      res = []
      Job.ms_reindex!

      puts "SETTINGS = #{index.get_settings}"

      query = params[:query]
      job_type = params[:job_type]
      sort_by = params[:sort_by]

      filters = []
      if job_type.present?
        filters << "job_type = #{job_type}"
      end

      if sort_by.present?
        case sort_by
        when 'salary_desc'
          sort = 'salary:desc'
        when 'salary_asc'
          sort = 'salary:asc'
        when 'date_desc'
          sort = 'created_at:desc'
        when 'date_asc'
          sort = 'created_at:asc'
        end
        query_options = {
          filter: [filters.join(' AND ')],
          sort: [sort]
        }
      else
        query_options = {
          filter: [filters.join(' AND ')]
        }
      end

      # Perform the search
      index.search(query, query_options)['hits'].map do |hit|
        res << Job.find(hit['id'])
      end
      @jobs = res
    rescue MeiliSearch::ApiError => e
      Rails.logger.error "MeiliSearch error: #{e.message}"
      @jobs = []
    end

  end

  def client
    @client ||= MeiliSearch::Client.new(ENV['MEILISEARCH_URL'], ENV['MEILISEARCH_API_KEY'])
  end

  private

  # Method to communicate with the FG-API by sending a POST-request to tbd
  def call_feed(jobs)
    url = URI.parse("https://embloy-fg-api.onrender.com/feed")

    if Current.user.nil? || Current.user.preferences.nil?
      request_body = "{\"slice\": #{jobs.to_json}}"
    else
      request_body = "{\"pref\": #{Current.user.preferences.to_json},\"slice\": #{jobs.to_json}}"
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
      @jobs = []
      feed_json.each do |job_hash|
        @jobs << Job.new(job_hash)
      end
      @jobs
    end
  end

  def job_params
    params.require(:job).permit(:title, :description, :content, :job_notifications, :start_slot, :notify, :status, :user_id, :longitude, :latitude, :job_type, :position, :currency, :salary, :key_skills, :duration)
  end

  def mark_notifications_as_read
    if Current.user
      notifications_to_mark_as_read = @job.notifications_as_job.where(recipient: Current.user)
      notifications_to_mark_as_read.update_all(read_at: Time.zone.now)
    end
  end
end
