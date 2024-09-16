# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'UserController', type: :routing do
  describe 'routing' do
    it 'routes to #show' do
      expect(get: '/api/v0/user').to route_to('api/v0/user#show', format: 'json')
    end

    it 'routes to #edit' do
      expect(patch: '/api/v0/user').to route_to('api/v0/user#edit', format: 'json')
    end

    it 'routes to #destroy' do
      expect(delete: '/api/v0/user').to route_to('api/v0/user#destroy', format: 'json')
    end

    it 'routes to #own_jobs' do
      expect(get: '/api/v0/user/jobs').to route_to('api/v0/user#own_jobs', format: 'json')
    end

    it 'routes to #own_applications' do
      expect(get: '/api/v0/user/applications').to route_to('api/v0/user#own_applications', format: 'json')
    end

    it 'routes to #own_reviews' do
      expect(get: '/api/v0/user/reviews').to route_to('api/v0/user#own_reviews', format: 'json')
    end

    it 'routes to #upcoming' do
      expect(get: '/api/v0/user/upcoming').to route_to('api/v0/user#upcoming', format: 'json')
    end

    it 'routes to #remove_image' do
      expect(delete: '/api/v0/user/image').to route_to('api/v0/user#remove_image', format: 'json')
    end

    it 'routes to #upload_image' do
      expect(post: '/api/v0/user/image').to route_to('api/v0/user#upload_image', format: 'json')
    end

    it 'routes to #events' do
      expect(get: '/api/v0/user/events').to route_to('api/v0/user#events', format: 'json')
    end

    it 'routes to #preferences' do
      expect(get: '/api/v0/user/preferences').to route_to('api/v0/user#preferences', format: 'json')
    end

    it 'routes to #update_preferences' do
      expect(patch: '/api/v0/user/preferences').to route_to('api/v0/user#update_preferences', format: 'json')
    end
  end
end
