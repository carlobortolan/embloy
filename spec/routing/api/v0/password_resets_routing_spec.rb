# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'PasswordResetsController', type: :routing do
  describe 'routing' do
    it 'routes to #create' do
      expect(post: '/api/v0/user/password/reset').to route_to('api/v0/password_resets#create', format: 'json')
    end

    it 'routes to #update' do
      expect(patch: '/api/v0/user/password/reset').to route_to('api/v0/password_resets#update', format: 'json')
    end
  end
end
