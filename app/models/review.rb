# frozen_string_literal: true

# The Review class represents a review in the application.
class Review < ApplicationRecord
  enum :rating, { one_star: '1', two_star: '2', three_star: '3', four_star: '4', five_star: '5' }
  acts_as_paranoid
  validates :rating, presence: true
  validates :message, presence: false
  validates :created_by, presence: true
end
