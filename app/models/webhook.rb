# frozen_string_literal: true

# The Webhook class represents a user's registered webhook
class Webhook < ApplicationRecord
  belongs_to :user

  validates :url, presence: true # e.g., 'https://api.embloy.com/api/v0/webhooks/lever'
  validates :event, presence: true # e.g., 'applicationCreated'
  validates :source, presence: true # e.g., 'lever'
  validates :ext_id, presence: true # e.g., Lever webhook ID
end
