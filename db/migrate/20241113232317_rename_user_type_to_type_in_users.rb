# frozen_string_literal: true

class RenameUserTypeToTypeInUsers < ActiveRecord::Migration[7.0]
  def up
    # Rename the column and change its type to string
    rename_column :users, :user_type, :type
    change_column :users, :type, :string, default: 'PrivateUser', null: false

    # Drop the existing enum type
    execute <<-SQL
      DROP TYPE IF EXISTS user_type CASCADE;
    SQL
  end

  def down
    # Recreate the old enum type
    execute <<-SQL
      CREATE TYPE user_type AS ENUM ('private', 'company');
    SQL

    # Rename the column back to user_type and change its type to enum
    rename_column :users, :type, :user_type
    change_column :users, :user_type, :enum, using: 'user_type::user_type', default: 'private', null: false
  end
end
