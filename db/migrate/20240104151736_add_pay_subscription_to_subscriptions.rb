# frozen_string_literal: true

class AddPaySubscriptionToSubscriptions < ActiveRecord::Migration[7.0]
  def change
    add_reference :subscriptions, :pay_subscription, foreign_key: { to_table: :pay_subscriptions }
  end
end
