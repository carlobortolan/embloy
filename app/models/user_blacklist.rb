# frozen_string_literal: true

# The UserBlacklist class represents a blacklist of users in the application.
class UserBlacklist < ApplicationRecord
  self.primary_key = :user_id
end
