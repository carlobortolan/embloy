require_relative '../../config/environment'

class JobSlicer
  # Fetches a slice (=partition) containing all relevant jobs for the current user
  # TODO: Implement using postgis
  def self.slice(user, rad = nil)
    if rad.nil?
      rad = 25000
    end
    puts "STARTED SLICING"
    #SpatialJobValue.geo_query(user.latitude, user.longitude, rad, 500) #todo: add functionality that dynamically adapts rad according to the density of jobs in the area (to better consider differences between very densely populated urban areas and rural areas)
    puts "ENDED SLICING"
    Job.all.limit(50)
  end
  private

end
