class AddJobCounterCacheToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :jobs_count, :integer, default: 0
  end
end
