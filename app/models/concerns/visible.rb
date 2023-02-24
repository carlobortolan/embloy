module Visible
  extend ActiveSupport::Concern

  VALID_STATUSES = ['public', 'private', 'archived']

  included do
    validates :status, inclusion: { in: VALID_STATUSES }
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
