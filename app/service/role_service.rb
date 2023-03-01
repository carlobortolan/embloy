# frozen_string_literal: true

class RoleService < ApplicationController

  def require_admin!
    return admin?(Current.user.user_role)
  end

  def require_editor!
    return editor?(Current.user.user_role)
  end

  def require_developer!
    return developer?(Current.user.user_role)
  end

  def require_moderator!
    return moderator?(Current.user.user_role)
  end

  def require_verified!
    return verified?(Current.user.user_role)
  end

  protected
  def set_current_user(id)
    Current.user = User.find_by(id: id)
    if Current.user.nil?
      raise RoleService::InvalidUser::Unknown
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


  class API

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

    #########################################################
    ################## DATABASE LOOKUP ######################
    #########################################################
    def require_admin!(id)
      set_current_user(id)
      return super.require_admin!
    end

    def require_editor!(id)
      set_current_user(id)
      return super.require_editor!
    end


    def require_developer!(id)
      set_current_user(id)
      return super.require_developer!
    end

    def require_moderator!(id)
      set_current_user(id)
      return super.require_moderator!
    end

    def require_verified!(id)
      set_current_user(id)
      return super.require_verified!
    end

  end

  class InvalidUser < StandardError
    class Unknown < StandardError
    end
    class LoggedOut < StandardError
    end
  end
end
=begin
def admin?
  if Current.user.user_role == "admin"
    true
  else
    false
  end
end

def editor?
  if Current.user.user_role == "admin" || Current.user.user_role == "editor"
    true
  else
    false
  end
end

def developer?
  if Current.user.user_role == "admin" || Current.user.user_role == "developer"
    true
  else
    false
  end
end

def moderator?
  if Current.user.user_role == "admin" || Current.user.user_role == "editor" || Current.user.user_role == "moderator"
    true
  else
    false
  end
end

def verified?
  if Current.user.user_role == "admin" || Current.user.user_role == "editor" || Current.user.user_role == "moderator" || Current.user.user_role == "verified"
    true
  else
    false
  end
end
=end