# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'NotificationsController', type: :routing do
  describe 'routing' do
    it 'routes to #show' do
      expect(get: '/api/v0/user/notifications').to route_to('api/v0/notifications#show', format: 'json')
    end

    it 'routes to #unread_applications' do
      expect(get: '/api/v0/user/notifications/unread').to route_to('api/v0/notifications#unread_applications', format: 'json')
    end

    it 'routes to #mark_as_read' do
      expect(patch: '/api/v0/user/notifications/1').to route_to('api/v0/notifications#mark_as_read', format: 'json', id: '1')
    end
  end
end
