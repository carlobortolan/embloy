class AdaptReviewTable < ActiveRecord::Migration[7.0]
  def change
    add_column :reviews, :job_id, :integer
    add_foreign_key :reviews, :jobs, column: :job_id, primary_key: :job_id

    add_column :reviews, :reviewer_id, :integer

  end
end
