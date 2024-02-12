# frozen_string_literal: true

class AddDeviseLockableToAdmins < ActiveRecord::Migration[7.0]
  def change
    add_column :admins, :locked_at, :datetime
    add_column :admins, :failed_attempts, :integer
    add_column :admins, :unlock_token, :string
    add_column :admins, :unlocked_at, :datetime
  end
end
