class ApplicationAttachment < ApplicationRecord
  # belongs_to :application, counter_cache: true, :dependent => :destroy
  belongs_to :job, :dependent => :destroy
  belongs_to :user, :dependent => :destroy

  has_one_attached :cv
  # validates :user_id
  # validates :job_id
end
