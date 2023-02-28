class AddApplicationCounterCacheToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :applications_count, :integer, default: 0
  end
end
