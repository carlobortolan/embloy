#########################################################
################## SUPER CONTROLLER #####################
#########################################################
class ApplicationController < ActionController::Base
  before_action :set_current_user
  before_action :set_notifications, if: Current.user
  before_action :require_user_not_blacklisted, if: Current.user

  def set_current_user
    Current.user = User.find_by(id: session[:user_id]) if session[:user_id]
  end

  # ============== Exceptions =============
  def require_user_logged_in
    if Current.user.nil?
      raise CustomExceptions::InvalidUser::LoggedOut
    end
  end

  def require_user_be_owner
    unless user_is_owner!
      raise CustomExceptions::Unauthorized::NotOwner
    end
  end

  def require_user_not_blacklisted
    if user_is_blacklisted!
      raise CustomExceptions::Unauthorized::Blocked
    end
  end

  # ============== Validations =============

  def require_user_logged_in!
    if Current.user.nil?
      redirect_to sign_in_path, alert: 'You must be logged in!'
      return false
    end
    true
  end

  # This method checks whether the currently signed in user is the owner of the job that is being requested.
  # If this is not the case, the user will be redirected back and not gain access to the resource.
  def require_user_be_owner!
    if user_is_owner!
      true
    else
      redirect_back(fallback_location: jobs_path, alert: 'Not allowed!')
      # job_path(@job), status: :unauthorized, alert: 'Not allowed'
      false
    end
  end

  # This method only checks whether the currently signed in user is the owner of the job that is being requested
  # and only returns a boolean.
  def user_is_owner!
    if Current.user.nil? || @job.nil? || @job.user_id != Current.user.id
      return false
    end
    true
  end

  # This method only checks whether the currently signed in user is the owner of the job that is being requested
  # and only returns a boolean.
  def user_is_blacklisted!
    if !Current.user.nil? && !UserBlacklist.find_by_user_id(Current.user.id).nil?
      true
    end
  end

  def require_user_admin!
    # if (Current.user.role = 'admin')
    #   true
    # else
    #   redirect_to sign_in_path, alert: 'Unauthorized!'
    # end
  end

  # ============== Standard error catching =============

  # rescue_from ::ActiveRecord::RecordNotFound, with: :record_not_found
  # rescue_from ::NameError, with: :err_server
  # rescue_from ::NoMethodError, with: :err_server
  # rescue_from ::ActionController::InvalidAuthenticityToken, with: :err_not_allowed
  # rescue_from ::ActionController::RoutingError, with: :err_server
  rescue_from ::AbstractController::DoubleRenderError, with: :err_server
  rescue_from ::CustomExceptions::Unauthorized::Blocked, with: :err_blocked

  protected

  def err_server
    render(:file => File.join(Rails.root, 'public/500.html'), :status => 500, :layout => false)
  end

  def err_not_allowed
    render(:file => File.join(Rails.root, 'public/403.html'), :status => 403, :layout => false)
  end

  def err_blocked
    render(:file => File.join(Rails.root, 'public/403_blocked.html'), :status => 403, :layout => false)
  end

  def record_not_found(exception)
    if Current.user
      # && Current.user.role == 'Admin'
      render json: { error: exception.message }.to_json, status: 404
    else
      err_not_allowed
    end
  end

  def routing_error(exception)
    render(:file => File.join(Rails.root, 'public/404.html'), :status => 404, :layout => false)
  end

  private

  # ============== Config =============

  def set_notifications
    notifications = Notification.includes(:recipient).where(recipient: Current.user).newest_first.limit(9)
    @unread = notifications.unread
    @read = notifications.read
  end

end