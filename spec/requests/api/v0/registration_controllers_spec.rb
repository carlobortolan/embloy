require 'rails_helper'

RSpec.describe "Api::V0::RegistrationControllers", type: :request do
  describe "GET /api/v0/registration_controllers" do
    it "works! (now write some real specs)" do
      get api_v0_registration_controllers_path
      expect(response).to have_http_status(200)
    end
  end
end
