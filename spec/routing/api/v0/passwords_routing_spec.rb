# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'PasswordsController', type: :routing do
  describe 'routing' do
    it 'routes to #update' do
      expect(patch: '/api/v0/user/password').to route_to('api/v0/passwords#update', format: 'json')
    end
  end
end
