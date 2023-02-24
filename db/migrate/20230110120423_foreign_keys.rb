class ForeignKeys < ActiveRecord::Migration[7.0]
  def change
    add_foreign_key :private_users, :users, column: :id, primary_key: :id
    add_foreign_key :company_users, :users, column: :id, primary_key: :id

    add_foreign_key :jobs, :users, column: :user_id, primary_key: :id

    add_foreign_key :applications, :users, column: :applicant_id, primary_key: :id
    add_foreign_key :applications, :jobs, column: :job_id, primary_key: :job_id

    add_foreign_key :notifications, :users, column: :employer_id, primary_key: :id
    add_foreign_key :notifications, :jobs, column: :job_id, primary_key: :job_id

    add_foreign_key :reviews, :users, column: :created_by, primary_key: :id
  end
end
