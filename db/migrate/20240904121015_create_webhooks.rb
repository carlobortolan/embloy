# frozen_string_literal: true

class CreateWebhooks < ActiveRecord::Migration[7.0]
  def change
    create_table :webhooks do |t|
      t.references :user, null: false, foreign_key: true
      t.string :url, null: false
      t.string :event, null: false
      t.string :source, null: false
      t.string :ext_id
      t.string :signatureToken
      t.boolean :active, default: true
      t.timestamps
    end

    add_index :webhooks, :ext_id, unique: true
  end
end
