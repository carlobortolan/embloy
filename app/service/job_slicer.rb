require_relative '../../config/environment'

class JobSlicer
  # Fetches a slice (=partition) containing all relevant jobs for the current user
  # TODO: Implement using postgis
  def self.slice(user)
    puts "STARTED SLICING"

    # Query method 1
    # jobs = Job.where("SELECT * FROM jobs LIMIT 5")

    # Query method 2
    # query = "SELECT * FROM jobs LIMIT 5"
    # results = ActiveRecord::Base.connection.execute(query)

    puts "ENDED SLICING"
    Job.find_by_sql("SELECT * FROM jobs WHERE salary = 789")
  end
end
