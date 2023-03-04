class AdaptReviewTable5 < ActiveRecord::Migration[7.0]
  def change
    rename_column :reviews, :subject_id, :subject
    change_column_null :reviews, :subject, false
  end
end
