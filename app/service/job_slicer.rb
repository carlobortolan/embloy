# frozen_string_literal: true

require_relative '../../config/environment'

# The JobSlicer class is responsible for fetching job data based on user's location and other parameters.
class JobSlicer
  # Fetches a slice (=partition) containing all relevant jobs for the current user's  (feed)
  # Used by API
  # TODO: Implement using postgis
  def self.slice(_user = nil, rad, lat, lng)
    rad, lat, lng = sanitize_inputs(rad, lat, lng)
    res = fetch_jobs_within_radius(lat, lng, rad, 20)
    res = fetch_all_jobs(20) if res.nil? || res.empty?
    res
  end

  # Fetches a limited number of jobs depending on the user's coordinates (map)
  # @deprecated
  def self.fetch(lat, lng)
    if lat.nil? || lng.nil? || lat.abs > 90.0 || lng.abs > 180.0
      lat = 48.1374300
      lng = 11.5754900
    end

    res = Job.within_radius(lat, lng, 1_000_000, 100).with_all_rich_text.includes(:rich_text_description,
                                                                                  image_url_attachment: :blob)

    if res.nil? || res.empty?
      res = Job.all.limit(10).with_all_rich_text.includes(
        :rich_text_description, image_url_attachment: :blob
      )
    end
    res
  end

  # Used by web app
  def self.fetch_feed(lat, lng)
    return Job.includes(image_url_attachment: :blob).order('random()').limit(20) if lat.nil? || lng.nil? || lat.abs > 90.0 || lng.abs > 180.0

    res = Job.includes(image_url_attachment: :blob).within_radius(
      lat, lng, 50_000, 20
    )
    res = Job.includes(image_url_attachment: :blob).all.limit(20) if res.nil? || res.empty?
    res
  end

  def self.fetch_map(lat, lng)
    return Job.order('random()').limit(100) if lat.nil? || lng.nil? || lat.abs > 90.0 || lng.abs > 180.0

    res = Job.within_radius(lat, lng, 1_000_000,
                            100)
    #      res = Job.within_radius(lat, lng, 1000000, 20)
    res = Job.all.limit(100) if res.nil? || res.empty?
    res
  end

  def self.sanitize_inputs(rad, lat, lng)
    rad = 25_000 if rad.nil?
    if lat.nil? || lng.nil? || lat.abs > 90.0 || lng.abs > 180.0
      lat = 48.1374300
      lng = 11.5754900
    end
    [rad, lat, lng]
  end

  def self.fetch_jobs_within_radius(lat, lng, rad, limit)
    Job.includes(:rich_text_description, image_url_attachment: :blob).within_radius(
      lat, lng, rad, limit
    )
  end

  def self.fetch_all_jobs(limit)
    Job.includes(:rich_text_description,
                 image_url_attachment: :blob).all.limit(limit)
  end
end
