# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'CompanyController', type: :routing do
  describe 'routing' do
    it 'routes to #feed' do
      expect(get: '/api/v0/company/1/feed').to route_to('api/v0/company#feed', format: 'json', id: '1')
    end
  end
end
