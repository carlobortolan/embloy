# frozen_string_literal: true

# The JobAssignment class represents a job assignment in the application.
class JobAssignment < ApplicationRecord
  acts_as_paranoid
  belongs_to :job, counter_cache: true
  belongs_to :user, counter_cache: true,
                    dependent: :destroy

  validates :user_id, presence: true
  validates :job_id, presence: true
end
