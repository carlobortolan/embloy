# frozen_string_literal: true

# The Subscription class represents a subscription in the application.
# It includes methods for activating, cancelling, and renewing the subscription.
class Subscription < ApplicationRecord
  belongs_to :user

  validates :tier, presence: { error: 'ERR_BLANK', description: "Attribute can't be blank" },
                   inclusion: { in: %w[basic premium enterprise_1 enterprise_2 enterprise_3], error: 'ERR_INVALID', description: 'Attribute is invalid' }
  validates :active,
            inclusion: { in: [true, false],
                         message: 'ERR_NOT_BOOL' }
  validates :expiration_date,
            presence: { error: 'ERR_BLANK',
                        description: "Attribute can't be blank" }
  validates :start_date,
            presence: { error: 'ERR_BLANK',
                        description: "Attribute can't be blank" }
  validates :auto_renew,
            presence: { error: 'ERR_BLANK',
                        description: "Attribute can't be blank" }

  def activate
    # TODO: Check if payment was successful
    self.active = true
    save
  end

  def cancel
    # TODO: Cancel payment if possible
    self.active = false
    save
  end

  def renew
    # TODO: Check if payment was successful
    self.active = true
    self.expiration_date = expiration_date + 6.month
    save
  end

  private

  def valid_subscription?
    expiration_date > Time.now.utc.to_date && active
  end
end
