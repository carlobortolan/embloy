module Admin
  class AdminController < ApplicationController
    before_action :require_user_logged_in
    before_action :require_user_not_blacklisted!
    before_action :must_be_admin!
    layout 'admin_layouts/application'

    def index
      @users_total = User.count
      @jobs_total = Job.count
      @applications_total = Application.count

      @new_users = User.find_by_sql("
      SELECT created_at::date, COUNT(*)
      FROM users
      WHERE created_at > now() - interval '7 days'
      GROUP BY created_at::date
      ORDER BY created_at::date ASC;")
      @new_jobs = Job.find_by_sql("
      SELECT created_at::date, COUNT(*)
      FROM jobs
      WHERE created_at > now() - interval '7 days'
      GROUP BY created_at::date
      ORDER BY created_at::date ASC;")
      @new_applications = Application.find_by_sql("
      SELECT updated_at::date, COUNT(*)
      FROM applications
      WHERE updated_at > now() - interval '7 days'
      GROUP BY updated_at::date
      ORDER BY updated_at::date ASC;")
      @recent_users = User.last(3)
      @recent_jobs = Job.last(3)
      @recent_applications = Application.find_by_sql("SELECT * FROM APPLICATIONS ORDER BY updated_at DESC LIMIT 5")
    end

    def users
    end

    def users_active
      @users = User.all.where(activity_status: 1).order("id").limit(100)
    end

    def users_admins
      @users = User.all.where(user_role: "admin").order("id").limit(100)
    end

    def users_editors
      @users = User.all.where(user_role: "editor").order("id").limit(100)
    end

    def users_moderators
      @users = User.all.where(user_role: "moderator").order("id").limit(100)
    end

    def jobs
    end

    def applications
    end

    def reviews
    end

  end
end
