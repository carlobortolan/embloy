# frozen_string_literal: true

# The ApplicationEvent class represents an event that occurs during the application pipeline.
class ApplicationEvent < ApplicationRecord
  belongs_to :application, foreign_key: %i[user_id job_id], primary_key: %i[user_id job_id]
  belongs_to :user
  belongs_to :job

  validates :event_type, presence: true
end
