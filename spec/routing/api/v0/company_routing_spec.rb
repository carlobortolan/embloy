# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'CompanyController', type: :routing do
  describe 'routing' do
    it 'routes to #board' do
      expect(get: '/api/v0/company/1/board').to route_to('api/v0/company#board', format: 'json', id: '1')
    end

    it 'routes to #job' do
      expect(get: '/api/v0/company/1/board/2').to route_to('api/v0/company#job', format: 'json', id: '1', job_slug: '2')
    end

    it 'routes to #show' do
      expect(get: '/api/v0/company/1').to route_to('api/v0/company#show', format: 'json', id: '1')
    end

    it 'routes to #create' do
      expect(post: '/api/v0/company').to route_to('api/v0/company#create', format: 'json')
    end

    it 'routes to #update' do
      expect(patch: '/api/v0/company/1').to route_to('api/v0/company#update', format: 'json', id: '1')
    end

    it 'routes to #destroy' do
      expect(delete: '/api/v0/company/1').to route_to('api/v0/company#destroy', format: 'json', id: '1')
    end
  end
end
