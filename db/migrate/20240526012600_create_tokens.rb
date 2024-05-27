# frozen_string_literal: true

class CreateTokens < ActiveRecord::Migration[7.0]
  def change
    create_table :tokens do |t|
      t.string :name, null: false
      t.string :token_type, null: false # e.g., 'api_key', 'access_token', 'refresh_token', 'request_token', 'client_token', etc.
      t.string :issuer # e.g., 'embloy', 'ashby', 'lever', 'softgarden', etc.
      t.string :encrypted_token, null: false
      t.string :encrypted_token_iv, null: false
      t.datetime :issued_at, null: false, precision: nil
      t.datetime :expires_at, null: false, precision: nil
      t.datetime :last_used_at, precision: nil
      t.boolean :active, null: false, default: true
      t.string :scopes # e.g., 'read', 'write', 'delete', 'admin', etc. <-- not supported yet, but placeholder for future use
      t.references :user, null: false, foreign_key: true
      t.timestamps
    end
  end
end
