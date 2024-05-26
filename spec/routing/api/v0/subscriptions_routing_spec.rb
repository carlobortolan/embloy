# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'SubscriptionsController', type: :routing do
  describe 'routing' do
    it 'routes to #all_subscriptions' do
      expect(get: '/api/v0/client/subscriptions').to route_to('api/v0/subscriptions#all_subscriptions', format: 'json')
    end

    it 'routes to #active_subscription' do
      expect(get: '/api/v0/client/subscriptions/active').to route_to('api/v0/subscriptions#active_subscription', format: 'json')
    end

    it 'routes to #all_charges' do
      expect(get: '/api/v0/client/subscriptions/charges').to route_to('api/v0/subscriptions#all_charges', format: 'json')
    end
  end
end
