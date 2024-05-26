# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'ReviewsController', type: :routing do
  describe 'routing' do
    it 'routes to #create' do
      expect(post: '/api/v0/user/1/reviews').to route_to('api/v0/reviews#create', format: 'json', id: '1')
    end

    it 'routes to #destroy' do
      expect(delete: '/api/v0/user/1/reviews').to route_to('api/v0/reviews#destroy', format: 'json', id: '1')
    end

    it 'routes to #update' do
      expect(patch: '/api/v0/user/1/reviews').to route_to('api/v0/reviews#update', format: 'json', id: '1')
    end
  end
end
