# frozen_string_literal: true

class UserRoleService < ApplicationController
  # frozen_string_literal: true

  #########################################################
  ################# WITH DATABASE LOOKUP ##################
  #########################################################
  def self.must_be_admin!(id = nil)
    # method can be called for a specific id or using Current.user from Application Controller
    set_current_id(id)
    return admin?(Current.user.user_role)
  end

  def self.must_be_editor!(id = nil)
    set_current_id(id)
    return editor?(Current.user.user_role)
  end

  def self.must_be_developer!(id = nil)
    set_current_id(id)
    return developer?(Current.user.user_role)
  end

  def self.must_be_moderator!(id = nil)
    set_current_id(id)
    return moderator?(Current.user.user_role)
  end

  def self.must_be_verified!(id = nil)
    set_current_id(id)
    return verified?(Current.user.user_role)
  end

  #########################################################
  ################# NO DATABASE LOOKUP ####################
  ########## USED FOR LOOKUP FREE TOKEN USAGE #############
  #########################################################
  def self.must_be_admin(user_role)
    return admin?(user_role)
  end

  def self.must_be_editor(user_role)
    return editor?(user_role)
  end

  def self.must_be_developer(user_role)
    return developer?(user_role)
  end

  def self.must_be_moderator(user_role)
    return moderator?(user_role)
  end

  def self.must_be_verified(user_role)
    return verified?(user_role)
  end

  protected

  def self.set_current_id(id = nil)
    if id.nil?
      if Current.user.nil?
        raise UserRoleService::InvalidUser::LoggedOut
      end
    else
      Current.user = User.find_by(id: id)
      if Current.user.nil?
        raise UserRoleService::InvalidUser::Unknown
      end
    end
  end

  def self.admin?(user_role)
    if user_role == "admin"
      true
    else
      false
    end
  end

  def self.editor?(user_role)
    if user_role == "admin" || user_role == "editor"
      true
    else
      false
    end
  end

  def self.developer?(user_role)
    if user_role == "admin" || user_role == "developer"
      true
    else
      false
    end
  end

  def self.moderator?(user_role)
    if user_role == "admin" || user_role == "editor" || user_role == "moderator"
      true
    else
      false
    end
  end

  def self.verified?(user_role)
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
