class AdaptReviewTable3 < ActiveRecord::Migration[7.0]
  def change
    change_column :reviews, :review_id, :integer, auto_increment: true
  end
end
