# frozen_string_literal: true

class UserService
  def initialize
    @user_repository = UserRepository.new
  end

  def add_user(user)
    @user_repository.add_user(user)
    user.user_type.eql? "company" ? @user_repository.add_company(user) : @user_repository.add_private(user)
  end

  def remove_user(id)
    @user_repository.remove_user(id)
  end

  def find_user(id)
    @user_repository.find_user(id)
  end

  def find_all
    @user_repository.find_all
  end

  def get_user(user_id)
    @user_repository.get_user(user_id)
  end

  def get_user_name(user_id)
    if !user_id.nil? && user_id.is_a?(Integer)
      @user_repository.get_user_name(user_id)
    end
  end

end
