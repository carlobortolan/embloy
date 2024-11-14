# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'JobListsController', type: :routing do
  describe 'routing' do
    it 'routes to #index' do
      expect(get: '/api/v0/job_lists').to route_to('api/v0/job_lists#index', format: 'json')
    end

    it 'routes to #create' do
      expect(post: '/api/v0/job_lists').to route_to('api/v0/job_lists#create', format: 'json')
    end

    it 'routes to #show' do
      expect(get: '/api/v0/job_lists/1').to route_to('api/v0/job_lists#show', id: '1', format: 'json')
    end

    it 'routes to #update via PUT' do
      expect(put: '/api/v0/job_lists/1').to route_to('api/v0/job_lists#update', id: '1', format: 'json')
    end

    it 'routes to #update via PATCH' do
      expect(patch: '/api/v0/job_lists/1').to route_to('api/v0/job_lists#update', id: '1', format: 'json')
    end

    it 'routes to #destroy' do
      expect(delete: '/api/v0/job_lists/1').to route_to('api/v0/job_lists#destroy', id: '1', format: 'json')
    end
  end
end