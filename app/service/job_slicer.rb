require_relative '../../config/environment'

class JobSlicer
  # Fetches a slice (=partition) containing all relevant jobs for the current user
  # TODO: Implement using postgis
  def self.slice(user)
    puts "STARTED SLICING"
    #jobs = SpatialJobValue::geo_query(user.latitude, user.longitude, 10000) #todo: add functionality that dynamically adapts rad according to the density of jobs in the area (to better consider differences between very densely populated urban areas and rural areas)
    # Query method 1
    # jobs = Job.where("SELECT * FROM jobs LIMIT 5")

    # Query method 2
    # query = "SELECT * FROM jobs LIMIT 5"
    # results = ActiveRecord::Base.connection.execute(query)

    puts "ENDED SLICING"
    Job.all.limit(50)
  end
end
