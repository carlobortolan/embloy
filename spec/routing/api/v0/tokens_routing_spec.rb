# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'TokensController', type: :routing do
  describe 'routing' do
    it 'routes to #index' do
      expect(get: '/api/v0/tokens').to route_to('api/v0/tokens#index', format: 'json')
    end

    it 'routes to #create' do
      expect(post: '/api/v0/tokens').to route_to('api/v0/tokens#create', format: 'json')
    end

    it 'routes to #update via PATCH' do
      expect(patch: '/api/v0/tokens/1').to route_to('api/v0/tokens#update', id: '1', format: 'json')
    end

    it 'routes to #destroy' do
      expect(delete: '/api/v0/tokens/1').to route_to('api/v0/tokens#destroy', id: '1', format: 'json')
    end
  end
end
