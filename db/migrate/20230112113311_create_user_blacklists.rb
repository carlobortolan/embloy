class CreateUserBlacklists < ActiveRecord::Migration[7.0]
  def change
    create_table :user_blacklists  do |t|
      t.integer :user_id, null: false
      t.integer :reason

      t.timestamps
      t.index [:user_id], name: "user_id_UNIQUE", unique: true
    end
  end
end
