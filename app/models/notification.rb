# frozen_string_literal: true

# The Notification class handles sending notifications in the application.
class Notification < ApplicationRecord
  include Noticed::Model
  belongs_to :recipient, polymorphic: true
end
