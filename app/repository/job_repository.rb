# frozen_string_literal: true
# TODO: Implement JobRepository
# TODO: ERROR CATCHING

class JobRepository

  def add_job(job)
    # ActiveRecord::Base.connection.execute("INSERT INTO jobs VALUES #{job}")
    query = "INSERT INTO jobs VALUES #{job}"
    binds = [ActiveRecord::Relation::QueryAttribute.new('job', job, ActiveRecord::Type::Job.new)]
    ApplicationRecord.connection.exec_query(query, 'SQL', binds, prepare: true)
  end

  def find_job(job_id)
    # ActiveRecord::Base.connection.execute("SELECT * FROM jobs WHERE id = #{id};")
    query = "SELECT * FROM jobs WHERE job_id = #{job_id};"
    binds = [ActiveRecord::Relation::QueryAttribute.new('job_id', job_id, ActiveRecord::Type::Integer.new)]
    ApplicationRecord.connection.exec_query(query, 'SQL', binds, prepare: true)
  end

  def find_all_jobs
    ActiveRecord::Base.connection.execute("SELECT * FROM jobs;")
  end

  def delete_job(job_id)
    query = "REMOVE * FROM jobs WHERE job_id = #{job_id};"
    binds = [ActiveRecord::Relation::QueryAttribute.new('job_id', job_id, ActiveRecord::Type::Integer.new)]
    ApplicationRecord.connection.exec_query(query, 'SQL', binds, prepare: true)
  end

  def insert_notification (job_id, employer_id, new_value)
    # query = "INSERT INTO notifications (notify, job_id,employer_id) VALUES( '#{(new_value ? '1' : '0')}',#{job_id},#{employer_id});"
    # binds = [ActiveRecord::Relation::QueryAttribute.new('new_value', new_value, ActiveRecord::Type::Boolean.new),
    #          ActiveRecord::Relation::QueryAttribute.new('job_id', job_id, ActiveRecord::Type::Integer.new),
    #          ActiveRecord::Relation::QueryAttribute.new('employer_id', employer_id, ActiveRecord::Type::Integer.new)]
    # ApplicationRecord.connection.exec_query(query, 'SQL', binds, prepare: true)
  end

  def update_notification (job_id, employer_id, new_value)
    query = "UPDATE notifications SET notify = '#{(new_value ? 1 : 0)}' WHERE job_id = #{job_id} AND employer_id = #{employer_id}"
    binds = [ActiveRecord::Relation::QueryAttribute.new('new_value', new_value, ActiveRecord::Type::Boolean.new),
             ActiveRecord::Relation::QueryAttribute.new('job_id', job_id, ActiveRecord::Type::Integer.new),
             ActiveRecord::Relation::QueryAttribute.new('employer_id', employer_id, ActiveRecord::Type::Integer.new)]
    ApplicationRecord.connection.exec_query(query, 'SQL', binds, prepare: true)
  end

end
