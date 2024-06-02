# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'GeniusQueriesController', type: :routing do
  describe 'routing' do
    it 'routes to #query' do
      expect(get: '/api/v0/resource/1').to route_to('api/v0/genius_queries#query', genius: '1', format: 'json')
    end

    it 'routes to #create' do
      expect(post: '/api/v0/resource').to route_to('api/v0/genius_queries#create', format: 'json')
    end
  end
end
