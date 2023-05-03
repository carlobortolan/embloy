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

    # Default value for Faker-jobs
    if job_type_id.nil?
      job_type_id = 5
    end

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

  # TODO: add external api for exchange rate conversion
=begin
  def self.retrieve_records_within_range(x_min, y_min, x_max, y_max, max_records)
    distance = 0.1
    limit = 100
    num_records = 0
    while num_records < max_records && distance < 10
      sql = "SELECT COUNT(*) FROM jobs WHERE ST_DWithin(job_value::geometry, ST_MakeEnvelope(#{x_min}, #{y_min}, #{x_max}, #{y_max}, 4326), #{distance})"
      count = ActiveRecord::Base.connection.select_all(sql).first['count'].to_i
      puts count
      if count > max_records
        distance *= 2
      else
        limit = max_records - num_records
        break
      end
    end
    sql = "SELECT * FROM jobs WHERE ST_DWithin(job_value::geometry, ST_MakeEnvelope(#{x_min}, #{y_min}, #{x_max}, #{y_max}, 4326), #{distance}) LIMIT #{limit}"
    ActiveRecord::Base.connection.select_all(sql)
  end
=end

end
