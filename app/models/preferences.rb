class Preferences < ApplicationRecord
  belongs_to :user, :dependent => :destroy

  validates :interests, presence: false
  validates :experience, presence: false
  validates :degree, presence: false
  validates :num_jobs_done, presence: false
  validates :gender, presence: false
  validates :spontaneity, presence: false
  validates :job_types, presence: false
  validates :key_skills, presence: false
  validates :salary_range, presence: false

  attribute :job_types, :json
  attribute :salary_range, :float, array: true
end