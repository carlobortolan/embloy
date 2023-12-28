# frozen_string_literal: true

# The Current class represents the current state of a user in the application
class Current < ActiveSupport::CurrentAttributes
  attribute :user
end
