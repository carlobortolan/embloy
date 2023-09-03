require_relative '../../config/environment'

class JobSlicer
  # Fetches a slice (=partition) containing all relevant jobs for the current user's  (feed)
  # Used by API
  # TODO: Implement using postgis
  def self.slice(user = nil, rad, lat, lng)
    # `user` could be used for logging or special slicing (categories etc.) ...
    if rad.nil?
      rad = 25000
    end
    if lat.nil? || lng.nil? || lat.abs > 90.0 || lng.abs > 180.0
      lat = 48.1374300
      lng = 11.5754900
    end
    # TODO: Add functionality that dynamically adapts rad according to the density of jobs in the area (to better consider differences between very densely populated urban areas and rural areas)
    res = Job.includes(:rich_text_description, image_url_attachment: :blob).within_radius(lat, lng, rad, 20)
    if res.nil? || res.empty?
      res = Job.includes(:rich_text_description, image_url_attachment: :blob).all.limit(20)
    end
    return res
  end

  # Fetches a limited number of jobs depending on the user's coordinates (map)
  # @deprecated
  def self.fetch(lat, lng)
    if lat.nil? || lng.nil? || lat.abs > 90.0 || lng.abs > 180.0
      lat = 48.1374300
      lng = 11.5754900
    end

    res = Job.within_radius(lat, lng, 1000000, 100).with_all_rich_text.includes(:rich_text_description, image_url_attachment: :blob)

    if res.nil? || res.empty?
      res = Job.all.limit(10).with_all_rich_text.includes(:rich_text_description, image_url_attachment: :blob)
    end
    return res
  end

  # Used by web app
   def self.fetch_feed(lat, lng)
    if lat.nil? || lng.nil? || lat.abs > 90.0 || lng.abs > 180.0
      return Job.includes(image_url_attachment: :blob).order('random()').limit(20)
    else
      res = Job.includes(image_url_attachment: :blob).within_radius(lat, lng, 50000, 20)
      if res.nil? || res.empty?
        res = Job.includes( image_url_attachment: :blob).all.limit(20)
      end
      return res
    end
  end

  def self.fetch_map(lat, lng)
    if lat.nil? || lng.nil? || lat.abs > 90.0 || lng.abs > 180.0
      return Job.order('random()').limit(100)
    else
      res = Job.within_radius(lat, lng, 1000000, 100)
      #      res = Job.within_radius(lat, lng, 1000000, 20)
      if res.nil? || res.empty?
        res = Job.all.limit(100)
      end
      return res
    end
  end

end
