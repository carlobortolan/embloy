require 'rails_helper'

RSpec.describe "ApiV0s", type: :request do
  describe "GET /api_v0s" do
    it "works! (now write some real specs)" do
      get api_v0s_path
      expect(response).to have_http_status(200)
    end
  end
end
