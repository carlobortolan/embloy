# frozen_string_literal: true

module SpatialJobValue

  def self.update_job_value(test_job = nil)
    # Load the JSON file containing the job types mapping
    job_types_file = File.read(Rails.root.join('config', 'job_types.json'))
    job_types = JSON.parse(job_types_file)

    # Get the job type string from @job
    job_type = test_job.job_type

    # Map the job type string to an integer using the job types mapping
    job_type_id = job_types[job_type]

    # Update the job_value column with the 3D point using the mapped job type ID
    sql = "UPDATE jobs SET job_value = ST_SetSRID(ST_MakePoint(#{test_job.latitude}, #{test_job.longitude}, #{job_type_id}), 4326) WHERE job_id = #{test_job.job_id}"
    # Execute the SQL statement
    ActiveRecord::Base.connection.execute(sql)
  end

  def self.read_job_value(test_job = nil)
    result = ActiveRecord::Base.connection.execute("SELECT ST_AsText(job_value) FROM jobs WHERE job_id=#{test_job.job_id}").first
    point_string = result["st_astext"]
    latitude, longitude, job_type_id = point_string.scan(/[\d.-]+/)
    # return the values as a hash
    { latitude: latitude.to_f, longitude: longitude.to_f, job_type_id: job_type_id.to_i }
  end



end
