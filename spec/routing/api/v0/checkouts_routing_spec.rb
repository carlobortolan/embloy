# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'CheckoutsController', type: :routing do
  describe 'routing' do
    it 'routes to #show' do
      expect(post: '/api/v0/checkout').to route_to('api/v0/checkouts#show', format: 'json')
    end

    it 'routes to #subscriptionsuccess' do
      expect(get: '/api/v0/checkout/subscription/success').to route_to('api/v0/checkouts#subscriptionsuccess', format: 'json')
    end

    it 'routes to #paymentsuccess' do
      expect(get: '/api/v0/checkout/payment/success').to route_to('api/v0/checkouts#paymentsuccess', format: 'json')
    end

    it 'routes to #failure' do
      expect(get: '/api/v0/checkout/failure').to route_to('api/v0/checkouts#failure', format: 'json')
    end

    it 'routes to #billing' do
      expect(get: '/api/v0/billing').to route_to('api/v0/checkouts#billing', format: 'json')
    end

    it 'routes to #portal' do
      expect(get: '/api/v0/checkout/portal').to route_to('api/v0/checkouts#portal', format: 'json')
    end
  end
end
