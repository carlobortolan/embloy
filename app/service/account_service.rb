# frozen_string_literal: true

class AccountService
  def initialize
    @account_repository = AccountRepository.new
  end

  def get_account_name(user_id)
    if !user_id.nil? && user_id.is_a?(Integer)
      @account_repository.get_user_name(user_id)
    end
  end
end
