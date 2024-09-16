# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'WebhoooksController', type: :routing do
  describe 'routing' do
    it 'routes to #index' do
      expect(get: '/api/v0/user/webhooks').to route_to('api/v0/webhooks#index', format: 'json')
    end

    it 'routes to #refresh' do
      expect(post: '/api/v0/user/webhooks/lever').to route_to('api/v0/webhooks#refresh', format: 'json', source: 'lever')
    end

    it 'routes to #handle_event' do
      expect(post: '/api/v0/webhooks/lever/123').to route_to('hooks/webhooks#handle_event', source: 'lever', id: '123')
    end
  end
end
