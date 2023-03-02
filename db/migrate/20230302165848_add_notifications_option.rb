class AddNotificationsOption < ActiveRecord::Migration[7.0]
  def change
    change_table :users do |t|
      t.integer :application_notifications, default: 1, null: false
    end

    change_table :jobs do |t|
      t.integer :job_notifications, default: 1, null: false
    end
  end
end
