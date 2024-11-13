# frozen_string_literal: true

class CreateJobListItems < ActiveRecord::Migration[7.0]
  def change
    create_table :job_list_items do |t|
      t.references :job, null: false, foreign_key: { to_table: :jobs, primary_key: :job_id }
      t.references :job_list, null: false, foreign_key: true
      t.text :notes

      t.timestamps
    end
    add_index :job_list_items, %i[job_id job_list_id], unique: true
  end
end
