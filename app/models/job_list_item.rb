# frozen_string_literal: true

# The JobListItem model is a representation of a job that has been added to a job list.
class JobListItem < ApplicationRecord
  belongs_to :job
  belongs_to :job_list

  validates :job_id, presence: { error: 'ERR_BLANK', description: "Attribute can't be blank" },
                     uniqueness: { scope: :job_list_id, error: 'ERR_UNIQUE', description: 'Should be unique per job list' }
  validates :notes, length: { maximum: 255, message: 'cannot have more than 255 characters' }
end
