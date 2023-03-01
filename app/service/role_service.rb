# frozen_string_literal: true

class RoleService < ApplicationController

  #########################################################
  ################# WITH DATABASE LOOKUP ##################
  #########################################################
  def require_admin!(id = nil) #mehtod can be called for a specific id or using Curren.user from Application Controller
    set_current_id(id)
    return admin?(Current.user.user_role)
  end

  def require_editor!(id = nil)
    set_current_id(id)
    return editor?(Current.user.user_role)
  end

  def require_developer!(id = nil)
    set_current_id(id)
    return developer?(Current.user.user_role)
  end

  def require_moderator!(id = nil)
    set_current_id(id)
    return moderator?(Current.user.user_role)
  end

  def require_verified!(id = nil)
    set_current_id(id)
    return verified?(Current.user.user_role)
  end

  #########################################################
  ################# NO DATABASE LOOKUP ####################
  ########## USED FOR LOOKUP FREE TOKEN USAGE #############
  #########################################################
  def require_admin(user_role)
    return super.admin?(user_role)
  end

  def require_editor(user_role)
    return super.editor?(user_role)
  end

  def require_developer(user_role)
    return super.developer?(user_role)
  end

  def require_moderator(user_role)
    return super.moderator?(user_role)
  end

  def require_verified(user_role)
    return super.verified?(user_role)
  end

  protected

  def set_current_id(id = nil)
    if id.nil?
      if Current.user.nil?
        raise RoleService::InvalidUser::LoggedOut
      end
    else
      Current.user = User.find_by(id: id)
      if Current.user.nil?
        raise RoleService::InvalidUser::Unknown
      end
    end
  end

  def admin?(user_role)
    if user_role == "admin"
      true
    else
      false
    end
  end

  def editor?(user_role)
    if user_role == "admin" || user_role == "editor"
      true
    else
      false
    end
  end

  def developer?(user_role)
    if user_role == "admin" || user_role == "developer"
      true
    else
      false
    end
  end

  def moderator?(user_role)
    if user_role == "admin" || user_role == "editor" || user_role == "moderator"
      true
    else
      false
    end
  end

  def verified?(user_role)
    if user_role == "admin" || user_role == "editor" || user_role == "moderator" || user_role == "verified"
      true
    else
      false
    end
  end

  class InvalidUser < StandardError
    class Unknown < StandardError
    end

    class LoggedOut < StandardError
    end
  end
end

