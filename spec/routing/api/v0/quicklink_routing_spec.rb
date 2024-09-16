# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'QuicklinkController', type: :routing do
  describe 'routing' do
    it 'routes to #create_request' do
      expect(post: '/api/v0/sdk/request/auth/token').to route_to('api/v0/quicklink#create_request', format: 'json')
    end

    it 'routes to #create_request_proxy' do
      expect(post: '/api/v0/sdk/request/auth/proxy').to route_to('api/v0/quicklink#create_request_proxy', format: 'json')
    end

    it 'routes to #handle_request' do
      expect(post: '/api/v0/sdk/request/handle').to route_to('api/v0/quicklink#handle_request', format: 'json')
    end

    it 'routes to #apply' do
      expect(post: '/api/v0/sdk/apply').to route_to('api/v0/quicklink#apply', format: 'json')
    end
  end
end
