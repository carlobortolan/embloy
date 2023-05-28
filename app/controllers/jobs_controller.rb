require_relative '../../lib/feed_generator.rb'

class JobsController < ApplicationController
  before_action :require_user_logged_in, except: %w[index show find parse_inputs map update_jobs]
  layout 'job_applic_layout', :only => "edit"

  # Creates feed based on current user's preferences (if available); if the current user is not verified yet or
  # isn't logged in, his feed consists of random jobs (limit 100)
  def index
    # TODO: Get User Coordinates (currently saved directly as latitude, longitude in DB)
    unless Current.user.nil?
      lat = Current.user.latitude
      lng = Current.user.longitude
    else
      lat = 48.1374300
      lng = 11.5754900
    end

    # Slice jobs
    jobs = JobSlicer.slice(Current.user, 30000, lat, lng)

    # Call FG-API to rank jobs
    if !jobs.nil? && !jobs.empty?
      # TODO: Add pagination to feed / slicer @jobs = call_feed(jobs[params[:page]])
      @jobs = call_feed(jobs)
    else
      render status: 204, json: { "message": "No jobs found!" }
    end
  end

  def map
    lat = params[:latitude]
    lng = params[:longitude]
    if (lat.nil? || lng.nil?) && !Current.user.nil? && !Current.user.longitude.nil? && !Current.user.latitude.nil?
      lat = Current.user.latitude
      lng = Current.user.longitude
      @jobs = JobSlicer.fetch(lat, lng)
    else
      @jobs = Job.order('random()').limit(500)
    end
  end

  def update_jobs
    puts "PARAA = #{params}"

    lat = params[:latitude]
    lng = params[:longitude]
    if (lat.nil? || lng.nil?) && !Current.user.nil? && !Current.user.longitude.nil? && !Current.user.latitude.nil?
      lat = Current.user.latitude
      lng = Current.user.longitude
    end
    @jobs = JobSlicer.fetch(lat, lng)
    respond_to do |format|
      format.json { render json: @jobs }
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
    @job.currency = "EUR"
    @categories_list = JSON.parse(File.read(Rails.root.join('app/helpers', 'job_types.json'))).keys
    @editing = false
  end

  def create
    @job = Job.new(job_params)
    @job.image_url.attach(params[:job][:image_url]) if params[:job][:image_url].present?

    @job.currency = "EUR"
    @job.user_id = Current.user.id

    job_types_file = File.read(Rails.root.join('app/helpers', 'job_types.json'))
    job_types = JSON.parse(job_types_file)
    job_type = @job.job_type
    @job.job_type_value = job_types[job_type]

    if @job.save! && @job.update(geocode(@job))
      SpatialJobValue.update_job_value(@job)
      redirect_to @job, notice: "Created new job"
    else
      render :new, status: :unprocessable_entity, alert: "Job has not been created"
    end
  end

  def edit
    @job = Job.find(params[:id])
    require_user_be_owner
    @categories_list = JSON.parse(File.read(Rails.root.join('app/helpers', 'job_types.json'))).keys
    @editing = true
  end

  def update
    @job = Job.find(params[:id])
    require_user_be_owner

    if @job.update(job_params) && @job.update(geocode(@job))
      @job.image_url.attach(params[:job][:image_url]) if params[:job][:image_url].present?
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

  def find
    @categories_list = JSON.parse(File.read(Rails.root.join('app/helpers', 'job_types.json'))).keys

    # @jobs = Job.search_for(params[:query])
    @jobs = Job.includes([:user]).includes([:image_url_attachment]).where("title ILIKE :query OR description ILIKE :query OR position ILIKE :query OR job_type ILIKE :query OR key_skills ILIKE :query OR address ILIKE :query OR city ILIKE :query OR postal_code ILIKE :query OR start_slot::text ILIKE :query", query: "%#{params[:query]}%")
               .page(params[:page])

    if @jobs.nil? || @jobs.empty?
      @jobs = Job.includes([:user]).includes([:image_url_attachment]).all
    end

    unless params[:job_type].nil? || params[:job_type].blank?
      @jobs = @jobs.includes([:user]).includes([:image_url_attachment]).where(job_type: params[:job_type])
    end

    case params[:sort_by]
    when "salary_asc"
      @jobs = @jobs.order(salary: :asc)
    when "salary_desc"
      @jobs = @jobs.order(salary: :desc)
    when "date_asc"
      @jobs = @jobs.order(created_at: :asc)
    when "date_desc"
      @jobs = @jobs.order(created_at: :desc)
    end

    @jobs = @jobs.page(params[:page]).per(24)
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

  def geocode(job)
    begin
      latitude = job.latitude
      longitude = job.longitude
      result = Geocoder.search("#{latitude},#{longitude}").first
      country_code = result.country_code
      postal_code = result.postal_code
      city = result.city
      address = result.address
      { country_code: country_code, postal_code: postal_code, city: city, address: address }
    rescue
      {}
    end
  end

  def job_params
    params.require(:job).permit(:title, :description, :content, :job_notifications, :start_slot, :notify, :status, :user_id, :longitude, :latitude, :job_type, :position, :currency, :salary, :key_skills, :duration)
  end

  def location_params
    params.require(:job).permit(:country_code, :postal_code, :city, :address)
  end

  def mark_notifications_as_read
    if Current.user
      notifications_to_mark_as_read = @job.notifications_as_job.where(recipient: Current.user)
      notifications_to_mark_as_read.update_all(read_at: Time.zone.now)
    end
  end
end
