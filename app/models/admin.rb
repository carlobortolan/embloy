# frozen_string_literal: true

# Admin class
class Admin < ApplicationRecord
  devise :database_authenticatable, :rememberable, :validatable, :lockable, :timeoutable, :trackable,
         lock_strategy: :failed_attempts, unlock_strategy: :time, maximum_attempts: 3, unlock_in: 1.hour,
         timeout_in: 15.minutes
end
