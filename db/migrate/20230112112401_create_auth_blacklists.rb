class CreateAuthBlacklists < ActiveRecord::Migration[7.0]
  def change
    create_table :auth_blacklists do |t|
      t.string :token, null: false, limit:500
      t.integer :reason, null: true

      t.timestamps
      t.index [:token], name: "token_UNIQUE", unique: true
    end
  end
end
