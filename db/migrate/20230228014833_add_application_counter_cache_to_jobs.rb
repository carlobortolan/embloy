class AddApplicationCounterCacheToJobs < ActiveRecord::Migration[7.0]
  def change
    add_column :jobs, :applications_count, :integer, default: 0
  end
end
