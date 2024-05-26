# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'AuthenticationsController', type: :routing do
  describe 'routing' do
    it 'routes to #create_refresh' do
      expect(post: '/api/v0/auth/token/refresh').to route_to('api/v0/authentications#create_refresh', format: 'json')
    end

    it 'routes to #create_access' do
      expect(post: '/api/v0/auth/token/access').to route_to('api/v0/authentications#create_access', format: 'json')
    end
  end
end
