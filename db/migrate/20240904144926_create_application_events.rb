# frozen_string_literal: true

class CreateApplicationEvents < ActiveRecord::Migration[7.0]
  def change
    create_table :application_events do |t|
      t.string :ext_id, limit: 100
      t.bigint :job_id, null: false
      t.bigint :user_id, null: false
      t.string :event_type, limit: 50
      t.text :event_details, limit: 500
      t.references :previous_event, foreign_key: { to_table: :application_events }
      t.references :next_event, foreign_key: { to_table: :application_events }
      t.timestamps
    end
  end
end
