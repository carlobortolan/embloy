class ProfileController < ApplicationController
  def index
    if require_user_logged_in!
      @user = Current.user
    end
  end

  def settings
    if require_user_logged_in!
      @user = Current.user
    end
  end

  def edit
    if require_user_logged_in!
      @user = Current.user
    end
  end
end
