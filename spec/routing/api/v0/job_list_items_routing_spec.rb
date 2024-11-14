# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'JobListItemsController', type: :routing do
  describe 'routing' do
    it 'routes to #create' do
      expect(post: '/api/v0/job_lists/1/items').to route_to('api/v0/job_list_items#create', job_list_id: '1', format: 'json')
    end

    it 'routes to #destroy' do
      expect(delete: '/api/v0/job_lists/1/items/1').to route_to('api/v0/job_list_items#destroy', job_list_id: '1', id: '1', format: 'json')
    end
  end
end