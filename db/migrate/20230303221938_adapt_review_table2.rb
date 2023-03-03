class AdaptReviewTable2 < ActiveRecord::Migration[7.0]
  def change
    add_column :reviews, :subject_id, :integer
    Review.reset_column_information
    Review.all.each do |review|
      review.update_attribute :subject_id, review.user_id
    end
    remove_column :reviews, :user_id
    add_column :reviews, :review_id, :primary_key
  end
end
