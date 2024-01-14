# frozen_string_literal: true

#########################################################
################### SUPER CONTROLLER ####################
#########################################################
class ApplicationController < ActionController::Base
  include SpatialJobValue

  # ============ WEB-APP BEFORE ACTIONS ==============
  before_action :set_current_user
  before_action :auth_prototype
  before_action :set_notifications, unless: -> { Current.user.nil? }
  before_action :require_user_not_blacklisted!, unless: -> { Current.user.nil? }

  # =============== Prototype auth-wall ===============
  def auth_prototype
    return if !Current.user.nil? && must_be_verified

    #      redirect_to sign_in_path, alert: 'Your account is not verified yet!'
    redirect_to sign_in_path,
                alert: 'Your account hasn\'t been activated yet!'
  end

  # def set_current_user
  #  return unless session[:user_id]
  #
  #   Current.user = User.find_by(id: session[:user_id])
  # end

  # =============== Blacklisted User Check ===============
  # ================ WITH DATABASE LOOKUP ================
  def require_user_not_blacklisted(id = nil)
    set_current_id(id)
    user_not_blacklisted(id)
  end

  def self.require_user_not_blacklisted(id = nil)
    set_current_id(id)
    user_not_blacklisted(id)
  end

  def require_user_not_blacklisted!(id = nil)
    set_current_id(id)
    user_not_blacklisted!(id)
  end

  def self.require_user_not_blacklisted!(id = nil)
    set_current_id(id)
    user_not_blacklisted!(id)
  end

  # =============== User Role Check ===============
  # ============ WITH DATABASE LOOKUP =============

  def must_be_admin(id = nil)
    # method can be called for a specific id or using Current.user from Application Controller
    set_current_id(id)
    admin(Current.user.user_role)
  end

  def self.must_be_admin(id = nil)
    # method can be called for a specific id or using Current.user from Application Controller
    set_current_id(id)
    admin(Current.user.user_role)
  end

  def must_be_admin!(id = nil)
    # method can be called for a specific id or using Current.user from Application Controller
    set_current_id(id)
    admin!(Current.user.user_role)
  end

  def self.must_be_admin!(id = nil)
    # method can be called for a specific id or using Current.user from Application Controller
    set_current_id(id)
    admin!(Current.user.user_role)
  end

  #--------------------------------------

  def must_be_editor(id = nil)
    set_current_id(id)
    editor(Current.user.user_role)
  end

  def self.must_be_editor(id = nil)
    set_current_id(id)
    editor(Current.user.user_role)
  end

  def must_be_editor!(id = nil)
    set_current_id(id)
    editor!(Current.user.user_role)
  end

  def self.must_be_editor!(id = nil)
    set_current_id(id)
    editor!(Current.user.user_role)
  end

  #--------------------------------------

  def must_be_developer(id = nil)
    set_current_id(id)
    developer(Current.user.user_role)
  end

  def self.must_be_developer(id = nil)
    set_current_id(id)
    developer(Current.user.user_role)
  end

  def must_be_developer!(id = nil)
    set_current_id(id)
    developer!(Current.user.user_role)
  end

  def self.must_be_developer!(id = nil)
    set_current_id(id)
    developer!(Current.user.user_role)
  end

  #--------------------------------------

  def must_be_moderator(id = nil)
    set_current_id(id)
    moderator(Current.user.user_role)
  end

  def self.must_be_moderator(id = nil)
    set_current_id(id)
    moderator(Current.user.user_role)
  end

  def must_be_moderator!(id = nil)
    set_current_id(id)
    moderator!(Current.user.user_role)
  end

  def self.must_be_moderator!(id = nil)
    set_current_id(id)
    moderator!(Current.user.user_role)
  end

  #--------------------------------------

  def must_be_verified(id = nil)
    set_current_id(id)
    verified(Current.user.user_role)
  end

  def self.must_be_verified(id = nil)
    set_current_id(id)
    verified(Current.user.user_role)
  end

  def must_be_verified!(id = nil)
    set_current_id(id)
    verified!(Current.user.user_role)
  end

  def self.must_be_verified!(id = nil)
    set_current_id(id)
    verified!(Current.user.user_role)
  end

  #--------------------------------------

  def must_be_subscribed(id = nil)
    set_current_id(id)
    Current.user.active_subscription
  end

  def self.must_be_subscribed(id = nil)
    set_current_id(id)
    Current.user.active_subscription
  end

  def must_be_subscribed!(id = nil)
    set_current_id(id)
    return if Current.user.active_subscription

    raise CustomExceptions::Subscription::ExpiredOrMissing
  end

  def self.must_be_subscribed!(id = nil)
    set_current_id(id)
    return if Current.user.active_subscription

    raise CustomExceptions::Subscription::ExpiredOrMissing
  end

  # ============== Helper methods =================
  # ===============================================

  # ====== that set Current to user for id  =======
  def set_current_id(id = nil)
    if id.nil?
      raise CustomExceptions::InvalidUser::LoggedOut if Current.user.nil?
    else
      Current.user = User.find_by(id:)
      raise CustomExceptions::InvalidUser::Unknown if Current.user.nil?
    end
  end

  def self.set_current_id(id = nil)
    if id.nil?
      raise CustomExceptions::InvalidUser::LoggedOut if Current.user.nil?
    else
      Current.user = User.find_by(id:)

      raise CustomExceptions::InvalidUser::Unknown if Current.user.nil?
    end
  end

  # =============== User Role Check ===============
  # ========== WITHOUT DATABASE LOOKUP ============

  def admin(user_role)
    user_role == 'admin'
  end

  def self.admin(user_role)
    user_role == 'admin'
  end

  def admin!(user_role)
    user_role == 'admin' ? true : taboo!
  end

  def self.admin!(user_role)
    user_role == 'admin' ? true : taboo!
  end

  #--------------------------------------

  def editor(user_role)
    %w[admin editor].include?(user_role)
  end

  def self.editor(user_role)
    %w[admin editor].include?(user_role)
  end

  def editor!(user_role)
    if %w[admin
          editor].include?(user_role)
      true
    else
      taboo!
    end
  end

  def self.editor!(user_role)
    if %w[admin
          editor].include?(user_role)
      true
    else
      taboo!
    end
  end

  #--------------------------------------

  def developer(user_role)
    %w[admin developer].include?(user_role)
  end

  def self.developer(user_role)
    %w[admin developer].include?(user_role)
  end

  def developer!(user_role)
    if %w[admin
          developer].include?(user_role)
      true
    else
      taboo!
    end
  end

  def self.developer!(user_role)
    if %w[admin
          developer].include?(user_role)
      true
    else
      taboo!
    end
  end

  #--------------------------------------

  def moderator(user_role)
    %w[admin editor moderator].include?(user_role)
  end

  def self.moderator(user_role)
    %w[admin editor moderator].include?(user_role)
  end

  def moderator!(user_role)
    if %w[admin editor
          moderator].include?(user_role)
      true
    else
      taboo!
    end
  end

  def self.moderator!(user_role)
    if %w[admin editor
          moderator].include?(user_role)
      true
    else
      taboo!
    end
  end

  #--------------------------------------

  def verified(user_role)
    %w[admin editor moderator
       verified].include?(user_role)
  end

  def self.verified(user_role)
    %w[admin editor moderator
       verified].include?(user_role)
  end

  def verified!(user_role)
    if %w[admin editor moderator
          verified].include?(user_role)
      true
    else
      taboo!
    end
  end

  def self.verified!(user_role)
    if %w[admin editor moderator
          verified].include?(user_role)
      true
    else
      taboo!
    end
  end

  # ============ that raise exceptions ============

  def taboo!
    raise CustomExceptions::Unauthorized::InsufficientRole
  end

  def self.taboo!
    raise CustomExceptions::Unauthorized::InsufficientRole
  end

  # =============== Job Role Check ================
  # ============ WITH DATABASE LOOKUP =============

  def must_be_owner(job_id = nil, user_id = nil)
    set_current_id(user_id)
    set_at_job(job_id)
    owner
  end

  def self.must_be_owner(job_id = nil, user_id = nil)
    set_current_id(user_id)
    set_at_job(job_id)
    owner
  end

  def must_be_owner!(job_id = nil, user_id = nil)
    set_current_id(user_id)
    set_at_job(job_id)
    owner!
  end

  def self.must_be_owner!(job_id = nil, user_id = nil)
    set_current_id(user_id)
    set_at_job(job_id)
    owner!
  end

  # =============== Blacklist Check ===============
  # ============ WITH DATABASE LOOKUP =============

  def user_not_blacklisted(id = nil)
    if id.nil?
      !Current.user.nil? && UserBlacklist.find_by_user_id(Current.user.id).nil?
    else
      !id.nil? && UserBlacklist.find_by_user_id(id).nil?
    end
  end

  def user_not_blacklisted!(id = nil)
    if id.nil? && !Current.user.nil? && !UserBlacklist.find_by_user_id(Current.user.id).nil?
      raise CustomExceptions::Unauthorized::Blocked
    elsif !id.nil? && !UserBlacklist.find_by_user_id(id).nil?
      raise CustomExceptions::Unauthorized::Blocked
    end
  end

  # ============== Helper methods =================
  # ===============================================

  # ======= that set "@job" to job for id  ========

  def set_at_job(job_id = nil)
    @job = Job.find_by(job_id:) unless job_id.nil?    

    raise CustomExceptions::InvalidJob::Unknown if @job.nil?
  end

  def self.set_at_job(job_id = nil)
    @job = Job.find_by(job_id:) unless job_id.nil?

    return unless @job.nil?

    raise CustomExceptions::InvalidJob::Unknown
  end

  # ======== that model the role hierarchy ========

  def owner
    !(Current.user.nil? || @job.nil? || @job.user_id != Current.user.id)
  end

  def self.owner
    !(Current.user.nil? || @job.nil? || @job.user_id != Current.user.id)
  end

  def owner!
    Current.user.nil? || @job.nil? || @job.user_id != Current.user.id ? raise(CustomExceptions::Unauthorized::NotOwner) : true
  end

  def self.owner!
    Current.user.nil? || @job.nil? || @job.user_id != Current.user.id ? raise(CustomExceptions::Unauthorized::NotOwner) : true
  end

  ####################################################################################################
  # Methods from above are used for the checks & exceptions
  # Methods below are needed for the redirects in the web-app
  ####################################################################################################

  # ============== Exceptions =============

  # def require_user_not_blacklisted!
  #  return if user_not_blacklisted
  ##
  #  raise CustomExceptions::Unauthorized::Blocked
  # end

  def require_user_logged_in
    if Current.user.nil?
      redirect_to sign_in_path,
                  alert: 'You must be logged in!'
      return false
    end
    true
  end

  # This method checks whether the currently signed in user is the owner of the job that is being requested.
  # If this is not the case, the user will be redirected back and not gain access to the resource.
  def require_user_be_owner
    if owner
      true
    else
      redirect_back(
        fallback_location: jobs_path, alert: 'Not allowed!'
      )
    end
  end

  # This method only checks whether the currently signed in user is the owner of the job that is being requested
  # and only returns a boolean.
  # def user_not_blacklisted
  #  !Current.user.nil? && !UserBlacklist.find_by_user_id(Current.user.id).nil?
  # end

  # ============== Standard error catching =============

  # rescue_from ::ActiveRecord::RecordNotFound, with: :record_not_found
  # rescue_from ::NameError, with: :err_server
  # rescue_from ::NoMethodError, with: :err_server
  # rescue_from ::ActionController::InvalidAuthenticityToken, with: :err_not_allowed
  # rescue_from ::ActionController::RoutingError, with: :err_server
  # rescue_from ::AbstractController::DoubleRenderError, with: :err_server
  # rescue_from ::CustomExceptions::Unauthorized::Blocked, with: :err_blocked
  # rescue_from ::ActiveRecord::RecordNotUnique, with: :err_not_allowed

  def err_server
    render(
      file: File.join(Rails.root,
                      'public/500.html'), status: 500, layout: false
    )
  end

  def err_not_allowed
    render(
      file: File.join(Rails.root,
                      'public/403.html'), status: 403, layout: false
    )
  end

  def err_blocked
    render(
      file: File.join(Rails.root,
                      'public/403_blocked.html'), status: 403, layout: false
    )
  end

  def record_not_found(exception)
    if must_be_admin
      (render json: { error: exception.message }.to_json,
              status: 404)
    else
      err_not_allowed
    end
  end

  def routing_error
    render(
      file: File.join(Rails.root,
                      'public/404.html'), status: 404, layout: false
    )
  end
end

private

# ============== Config =============

def set_notifications
  notifications = Notification.includes(:recipient).where(recipient: Current.user).newest_first.limit(9)
  @unread = notifications.unread
  @read = notifications.read
end
# end

# rubocop:enable Metrics/ClassLength
