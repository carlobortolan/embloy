class Review < ApplicationRecord
  validates :rating, presence: true
  validates :message, presence: false
  validates :created_by, presence: true
  belongs_to :user
end
