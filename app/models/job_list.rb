# frozen_string_literal: true

# The JobList model is a representation of a list of jobs that a user has created.
class JobList < ApplicationRecord
  belongs_to :user
  has_many :job_list_items, dependent: :destroy
  has_many :jobs, through: :job_list_items

  validates :name, presence: true
end
