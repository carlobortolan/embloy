# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'JobsController', type: :routing do
  describe 'routing' do
    it 'routes to #feed' do
      expect(get: '/api/v0/jobs').to route_to('api/v0/jobs#feed', format: 'json')
    end

    it 'routes to #show' do
      expect(get: '/api/v0/jobs/1').to route_to('api/v0/jobs#show', format: 'json', id: '1')
    end

    it 'routes to #map' do
      expect(get: '/api/v0/maps').to route_to('api/v0/jobs#map', format: 'json')
    end

    it 'routes to #find' do
      expect(get: '/api/v0/find').to route_to('api/v0/jobs#find', format: 'json')
    end

    it 'routes to #create' do
      expect(post: '/api/v0/jobs').to route_to('api/v0/jobs#create', format: 'json')
    end

    it 'routes to #update' do
      expect(patch: '/api/v0/jobs').to route_to('api/v0/jobs#update', format: 'json')
    end

    it 'routes to #destroy' do
      expect(delete: '/api/v0/jobs/1').to route_to('api/v0/jobs#destroy', format: 'json', id: '1')
    end

    it 'routes to #show_all' do
      expect(get: '/api/v0/applications').to route_to('api/v0/applications#show_all', format: 'json')
    end

    it 'routes to #show' do
      expect(get: '/api/v0/jobs/1/applications').to route_to('api/v0/applications#show', format: 'json', id: '1')
    end

    it 'routes to #show_single' do
      expect(get: '/api/v0/jobs/1/application').to route_to('api/v0/applications#show_single', format: 'json', id: '1')
    end

    it 'routes to #show_single' do
      expect(get: '/api/v0/jobs/1/applications/1').to route_to('api/v0/applications#show_single', format: 'json', id: '1', application_id: '1')
    end

    it 'routes to #create' do
      expect(post: '/api/v0/jobs/1/applications').to route_to('api/v0/applications#create', format: 'json', id: '1')
    end

    it 'routes to #accept' do
      expect(patch: '/api/v0/jobs/1/applications/1/accept').to route_to('api/v0/applications#accept', format: 'json', id: '1', application_id: '1')
    end

    it 'routes to #reject' do
      expect(patch: '/api/v0/jobs/1/applications/1/reject').to route_to('api/v0/applications#reject', format: 'json', id: '1', application_id: '1')
    end
  end
end
