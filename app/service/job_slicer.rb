class JobSlicer
  # Fetches a slice (=partition) containing all relevant jobs for the current user
  # TODO: Implement using postgis
  def self.slice(user)
    puts "STARTED SLICING"
    puts "Current.user = #{user}"
    puts "ENDED SLICING"
  end

end
