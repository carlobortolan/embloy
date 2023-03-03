class AdaptReviewTable4 < ActiveRecord::Migration[7.0]
  def change
    remove_column :reviews, :reviewer_id
    add_foreign_key :reviews, :users, column: :subject_id, primary_key: :id
  end
end
