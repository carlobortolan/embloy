# frozen_string_literal: true

# The Review class represents a review in the application.
class Review < ApplicationRecord
  acts_as_paranoid
  validates :rating, presence: true
  validates :message, presence: false
  validates :created_by, presence: true
end
