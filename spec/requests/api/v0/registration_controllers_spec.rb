require 'rails_helper'

RSpec.describe "Api::V0::RegistrationControllers", type: :request do
  describe "POST /api/v0/user" do
    context 'valid normal inputs' do
      let(:user_params) { FactoryBot.attributes_for(:user) }
      it "returns a 200" do

      end
    end

  end
end
