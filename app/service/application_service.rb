# frozen_string_literal: true
# @author Jan Hummel, Carlo Bortolan
# This class uses the ApplicationHelper to to handle applications
require_relative '../../lib/notification_generator.rb'
require_relative '../../lib/notification_generator.rb'

class ApplicationService
  # [ApplicationHelper] Communicates with db.
  attr_accessor(:application_repository, :notification_generator)

  def initialize(application_repository, notification_generator)
    if application_repository.nil?
      @application_repository = ApplicationRepository.new
      @notification_generator = NotificationGenerator.new
    else
      @application_repository = application_repository
      @notification_generator = notification_generator
    end
  end

  # Inserts new application into db and sends a notification message to the employer if he has turned on the notifications for this job.
  # @param [int] job_id Job
  # @param [int] applicant_id Id des Bewerbers
  # @param [String] content Bewerbungsschreiben
  # @param [String] documents Link zu den Bewerbungsunterlagen
  def add_application (job_id, applicant_id, content, documents)
    puts "T1"
    puts "job_id = #{job_id}"
    puts applicant_id
    puts content
    puts documents
    puts job_id.nil?
    puts applicant_id.nil?
    puts !job_id.is_a?(Integer)
    puts !applicant_id.is_a?(Integer)

    if job_id.nil? || applicant_id.nil? || !job_id.is_a?(Integer) || !applicant_id.is_a?(Integer) || job_id <= 0 || applicant_id <= 0
      return
    end
    puts "T2"
    @application_repository.create_application(job_id, applicant_id, content, documents)
    puts "T3"
    # employer_id = @application_repository.find_employer_id(job_id)
    # puts "T3"
    # if employer_id.nil? || !employer_id.is_a?(Integer) || employer_id <= 0
    #   return
    # end
    # puts "T4"
    # if [true].include? @application_repository.get_notification(job_id, employer_id)
    #   employer = @application_repository.find_user(employer_id)
    #   applicant = @application_repository.find_user(applicant_id)
    #   puts "T5"
    #   if employer.nil? || applicant.nil? || employer[:name].nil? || employer[:email].nil? || applicant[:name].nil? || applicant[:email].nil?
    #     return
    #   end
    #   puts "T6"
    #   @notification_generator.send_notification_employer(employer[:name], employer[:email], applicant[:name], applicant[:email], applicant_id, job_id, Time.now.getutc.ceil, content.nil? ? "" : content, documents.nil? ? "" : documents)
    #   puts "T7"
    # end
  end

  # @deprecated Eigentlich unnötig, da es reicht die Jobs zu löschen, wobei dann durch 'ON DELETE CASCADE' auch die Bewerbungen gelöscht werden
  # @param [Time] date_to Alle Bewerbungen für Jobs vor diesem Datum werden gelöscht
  def remove_old_applications (date_to)
    unless date_to.nil?
      @application_repository.remove_deprecated_applications(date_to)
    end
  end

  # Rejects single application and adds optional comment by employer.
  # @param [int] job_id Job
  # @param [int] user_id Id des Bewerbers
  # @param [String] comment Rückmeldung
  def reject (job_id, user_id, comment)
    if !user_id.nil? && !job_id.nil? && !comment.nil? && job_id.is_a?(Integer) && user_id.is_a?(Integer) && job_id > 0 && user_id > 0
      @application_repository.change_status(job_id, user_id, -1, comment.to_s)
    end
  end

  # Rejects single application and adds optional comment by employer.
  # @param [int] job_id Job
  # @param [String] comment Rückmeldung
  def reject_all (job_id, comment)
    if !job_id.nil? && !comment.nil? && job_id.is_a?(Integer) && job_id > 0
      @application_repository.reject_all(job_id, comment.to_s)
    end
  end

  # Accepts single application and adds optional comment by employer.
  # Sends notification message to accepted applicant.
  # Rejects all other pending applications for this job.
  # @param [int] job_id Job
  # @param [int] user_id Id des Bewerbers
  # @param [String] comment Rückmeldung
  def accept (job_id, user_id, comment)
    if !user_id.nil? && !job_id.nil? && !comment.nil? && job_id.is_a?(Integer) && user_id.is_a?(Integer) && job_id > 0 && user_id > 0
      applicant = @application_repository.find_user(user_id)
      if !applicant.nil? && !applicant[:name].nil? && !applicant[:email].nil?
        @application_repository.change_status(job_id, user_id, 1, comment.to_s)
        #@application_repository.change_status_all(job_id, account_id, -1, "<STANDARD REJECTION TEXT>")
        @notification_generator.send_notification_applicant(applicant[:name], applicant[:email], job_id, comment)
      end
    end
  end

  def find_by_user(user_id)
    if !user_id.nil? && user_id.is_a?(Integer) && user_id > 0
      @application_repository.find_by_user(user_id)
    end
  end
end

