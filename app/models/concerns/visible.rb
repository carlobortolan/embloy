# frozen_string_literal: true

# Describes a record's visibility
module Visible
  extend ActiveSupport::Concern

  VALID_STATUSES = %w[public private
                      archived].freeze

  included do
    validates :status,
              inclusion: { in: VALID_STATUSES, error: 'ERR_INVALID', description: 'Attribute is invalid' }
  end

  def archived?
    status == 'archived'
  end

  def private?
    status == 'private'
  end

  def public?
    status == 'public'
  end
end
