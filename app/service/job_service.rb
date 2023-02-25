# frozen_string_literal: true

class JobService
  def initialize
    @job_repository = JobRepository.new
  end

  def add_job(job)
    @job_repository.add_job(job)
  end

  def find_job(id)
    @job_repository.find_job(id)
  end

  def find_all_jobs
    @job_repository.find_all(job)
  end

  def match_jobs(prefiltered_jobs, query_params)
    FeedGenerator.initialize_feed(prefiltered_jobs, query_params)
  end

  def delete_job(id)
    @job_repository.delete_job(id)
  end

  # Sets the notifications for the employer of a certain job to on (true) or off (false).
  # @param [int] job_id Job
  # @param [int] employer_id Id des Arbeitgebers
  # @param [boolean] notify Notifications on/off
  def set_notification (job_id, employer_id, notify)
    if !job_id.nil? && !employer_id.nil? && job_id.is_a?(Integer) && employer_id.is_a?(Integer) && job_id > 0 && employer_id >= 0 && [true, false].include?(notify)
      @job_repository.insert_notification(job_id, employer_id, notify)
    end
  end

  # Sets the notifications for the employer of a certain job to on (true) or off (false).
  # @param [int] job_id Job
  # @param [int] employer_id Id des Arbeitgebers
  # @param [boolean] notify Notifications on/off
  def edit_notification (job_id, employer_id, notify)
    if !job_id.nil? && !employer_id.nil? && job_id.is_a?(Integer) && employer_id.is_a?(Integer) && job_id > 0 && employer_id >= 0 && [true, false].include?(notify)
      @job_repository.update_notification(job_id, employer_id, notify)
    end
  end

end
