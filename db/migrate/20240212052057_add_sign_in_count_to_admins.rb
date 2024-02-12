# frozen_string_literal: true

class AddSignInCountToAdmins < ActiveRecord::Migration[7.0]
  def change
    add_column :admins, :sign_in_count, :integer, default: 0
  end
end
