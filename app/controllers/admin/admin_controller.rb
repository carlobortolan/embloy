module Admin
  class AdminController < ApplicationController

    layout 'admin_layouts/application'

    def index
      @users_total = User.count
      @jobs_total = Job.count
      @applications_total = Application.count
      @new_users = User.find_by_sql("SELECT count(id) FROM USERS GROUP BY created_at")
      @new_jobs = Job.find_by_sql("SELECT count(job_id) FROM JOBS GROUP BY created_at")
      @new_applications = Application.find_by_sql("SELECT count(*) FROM APPLICATIONS GROUP BY updated_at")
      @recent_users = User.last
      @recent_jobs = Job.last(3)
    end

    def users
    end

    def users_active
      @users = User.all.where(activity_status: 1).order("id")
    end

    def users_admins
      @users = User.all.where(user_role: "admin").order("id")
    end

    def users_editors
      @users = User.all.where(user_role: "editor").order("id")
    end

    def users_moderators
      @users = User.all.where(user_role: "moderator").order("id")
    end

    def jobs
    end

    def applications
    end

    def reviews
    end

  end
end
