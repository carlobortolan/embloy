class AddRolesToUsers < ActiveRecord::Migration[7.0]
  def change
    create_enum :user_roles, ["admin", "editor", "developer", "moderator", "verified", "spectator"]
    change_table :users do |t|
      t.enum "user_role", enum_type: "user_roles", default: "spectator", null: false
    end
  end
end
