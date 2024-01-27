# frozen_string_literal: true

# This module handles operations related to spatial job values
module SpatialJobValue
  # TODO: Make module use @job in Application controller
  def self.update_job_value(job)
    job_type_id = JSON.parse(File.read(Rails.root.join('app/helpers', 'job_types.json')))[job.job_type] || 5
    sql = <<-SQL
    UPDATE jobs
    SET job_value = ST_SetSRID(ST_MakePoint($1, $2, $3), 4326)
    WHERE job_id = $4
    SQL
    ActiveRecord::Base.connection.raw_connection.exec_params(sql, [job.latitude, job.longitude, job_type_id, job.id])
  end

  #   def self.update_job_value(job = nil)
  #     # Load the JSON file containing the job types mapping
  #     job_types_file = File.read(Rails.root.join(
  #                                  'app/helpers', 'job_types.json'
  #                                ))
  #     job_types = JSON.parse(job_types_file)
  #
  #     # Get the job type string from @job
  #     job_type = job.job_type
  #
  #     # Map the job type string to an integer using the job types mapping
  #     job_type_id = job_types[job_type]
  #
  #     # Default value for Faker-jobs
  #     job_type_id = 5 if job_type_id.nil?
  #
  #     # Update the job_value column with the 3D point using the mapped job type ID
  #     sql = <<-SQL
  #       UPDATE jobs#{' '}
  #       SET job_value = ST_SetSRID(ST_MakePoint(#{job.latitude}, #{job.longitude}, #{job_type_id}), 4326)#{' '}
  #       WHERE job_id = #{job.job_id}
  #     SQL
  #     ActiveRecord::Base.connection.execute(sql)
  #   end

  #
  #   def self.read_job_value(job = nil)
  #     sql = "SELECT ST_AsText(job_value) FROM jobs WHERE job_id=#{job.job_id}"
  #     result = ActiveRecord::Base.connection.execute(sql).first
  #     point_string = result['st_astext']
  #     latitude, longitude, job_type_id = point_string.scan(/[\d.-]+/)
  #     # return the values as a hash
  #     { latitude: latitude.to_f,
  #       longitude: longitude.to_f, job_type_id: job_type_id.to_i }
  #   end
  #
  #   def self.find_cluster(_job = nil, eps = nil, minpoints = nil)
  #     eps = 0.1 if eps.nil?
  #     minpoints = 2 if minpoints.nil?
  #     sql = <<-SQL
  #       job_type, ST_ClusterDBSCAN(job_value, eps := #{eps}, minpoints := #{minpoints}) OVER () AS cluster_id,#{' '}
  #       ST_NumGeometries(ST_Collect(job_value)) AS cluster_size#{' '}
  #       FROM jobs#{' '}
  #       WHERE job_value IS NOT NULL
  #     SQL
  #     clusters = ActiveRecord::Base.connection.execute(sql)
  #     clusters.each do |cluster|
  #       puts "#{cluster.cluster_id}: #{cluster.cluster_size} jobs"
  #     end
  #   end
  #

  # TODO: add external api for exchange rate conversion
  #   def self.retrieve_records_within_range(x_min, y_min, x_max, y_max, max_records)
  #     distance = 0.1
  #     limit = 100
  #     num_records = 0
  #     while num_records < max_records && distance < 10
  #       sql = <<-SQL
  #         SELECT COUNT(*)
  #         FROM jobs
  #         WHERE ST_DWithin(job_value::geometry, ST_MakeEnvelope(#{x_min}, #{y_min}, #{x_max}, #{y_max}, 4326), #{distance})"
  #         count = ActiveRecord::Base.connection.select_all(sql).first['count'].to_i
  #       SQL
  #       puts count
  #       if count > max_records
  #         distance *= 2
  #       else
  #         limit = max_records - num_records
  #         break
  #       end
  #     end
  #     sql = "SELECT * FROM jobs WHERE ST_DWithin(job_value::geometry, ST_MakeEnvelope(#{x_min}, #{y_min}, #{x_max}, #{y_max}, 4326), #{distance}) LIMIT #{limit}"
  #     ActiveRecord::Base.connection.select_all(sql)
  #   end
end
