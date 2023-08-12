class CreateJobAssignments < ActiveRecord::Migration[7.0]
  def change
    create_table :job_assignments do |t|

      t.timestamps
    end
  end
end
