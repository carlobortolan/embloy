require_relative '../../config/environment'

class JobSlicer
  # Fetches a slice (=partition) containing all relevant jobs for the current user
  def self.slice(user)
    puts "STARTED SLICING"

    # TODO: Implement using postgis
    jobs = Job.where("SELECT * FROM jobs LIMIT 5")

    puts "ENDED SLICING"
  end

end
