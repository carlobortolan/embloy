# frozen_string_literal: true

module SpatialJobValue

  # TODO: Make module use @job in Application controller
  def self.update_job_value(job = nil)
    # Load the JSON file containing the job types mapping
    job_types_file = File.read(Rails.root.join('app/helpers', 'job_types.json'))
    job_types = JSON.parse(job_types_file)

    # Get the job type string from @job
    job_type = job.job_type

    # Map the job type string to an integer using the job types mapping
    job_type_id = job_types[job_type]

    # Update the job_value column with the 3D point using the mapped job type ID
    sql = "UPDATE jobs SET job_value = ST_SetSRID(ST_MakePoint(#{job.latitude}, #{job.longitude}, #{job_type_id}), 4326) WHERE job_id = #{job.job_id}"
    # Execute the SQL statement
    ActiveRecord::Base.connection.execute(sql)
  end

  def self.read_job_value(job = nil)
    sql = "SELECT ST_AsText(job_value) FROM jobs WHERE job_id=#{job.job_id}"
    result = ActiveRecord::Base.connection.execute(sql).first
    point_string = result["st_astext"]
    latitude, longitude, job_type_id = point_string.scan(/[\d.-]+/)
    # return the values as a hash
    { latitude: latitude.to_f, longitude: longitude.to_f, job_type_id: job_type_id.to_i }
  end

  def self.geo_query_jobs(lat, lon, rad)
    sql = "SELECT * FROM jobs WHERE ST_DWithin(job_value::geometry, ST_SetSRID(ST_MakePoint(#{lon}, #{lat}), 4326)::geography, #{rad} ORDER BY ST_Distance(job_value::geometry, ST_SetSRID(ST_MakePoint(#{lon}, #{lat}), 4326)::geography) LIMIT 500)"
    result = ActiveRecord::Base.connection.execute(sql)
  end



end
