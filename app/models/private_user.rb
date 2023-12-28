# frozen_string_literal: true

# The PrivateUser class represents a private user in the application.
class PrivateUser < User
  validates :private_attr, presence: true
  belongs_to :user
end
