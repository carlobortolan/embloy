# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'RegistrationsController', type: :routing do
  describe 'routing' do
    it 'routes to #create' do
      expect(post: '/api/v0/user').to route_to('api/v0/registrations#create', format: 'json')
    end
    it 'routes to #verify' do
      expect(get: '/api/v0/user/verify').to route_to('api/v0/registrations#verify', format: 'json')
    end

    it 'routes to #activate' do
      expect(get: '/api/v0/user/activate').to route_to('api/v0/registrations#activate', format: 'json')
    end

    it 'routes to #reactivate' do
      expect(post: '/api/v0/user/activate').to route_to('api/v0/registrations#reactivate', format: 'json')
    end
  end
end
