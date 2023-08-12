class JobAssignment < ApplicationRecord
  belongs_to :job, counter_cache: true
  belongs_to :user, counter_cache: true, :dependent => :destroy

  validates :user_id, presence: true
  validates :job_id, presence: true
end
