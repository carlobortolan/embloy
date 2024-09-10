# frozen_string_literal: true

# Default Rails ApplicationRecord class
class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class
  # TODO: Enable this once we have a replica database
  # connects_to database: { writing: :primary, reading: :primary_replica }
end
