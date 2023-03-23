class Preferences < ApplicationRecord
  belongs_to :user, :dependent => :destroy

  validates :job_type, presence: false
  validates :salary_range, presence: false
  validates :spontaneity, presence: false
  validates :key_skills, presence: false
  validates :job_types, presence: false
  validates :salary_range, presence: false

  attribute :job_types, :json
  attribute :salary_range, :float, array: true
end