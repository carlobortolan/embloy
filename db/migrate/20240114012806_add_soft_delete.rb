# frozen_string_literal: true

class AddSoftDelete < ActiveRecord::Migration[7.0]
  def change
    add_column :jobs, :deleted_at, :datetime
    add_index :jobs, :deleted_at
    add_column :applications, :deleted_at, :datetime
    add_index :applications, :deleted_at
    add_column :preferences, :deleted_at, :datetime
    add_index :preferences, :deleted_at
    add_column :reviews, :deleted_at, :datetime
    add_index :reviews, :deleted_at
  end
end
