class Job < ApplicationRecord
  include Visible
  has_many :applications, dependent: :delete_all
  has_many :notifications, dependent: :delete_all
  belongs_to :user
  validates :title, presence: true
  validates :description, presence: true, length: { minimum: 10 }
  validates :start_slot, presence: true
  validates :longitude, presence: true
  validates :latitude, presence: true

  def profile
    @job.update(view_count: @job.view_count + 1)
  end
end
