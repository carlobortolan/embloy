require 'rails_helper'

RSpec.describe "Api::V0::RegistrationControllers" do
  before :all do
    # User.delete_all
    @valid_user_params = []
    10.times do
      fn = Faker::Name.first_name
      ln = Faker::Name.last_name
      mail = "#{fn}.#{ln}@fake_tests_12345.com"
      pw = Faker::Job.name
      pw_conf = pw
      params = { email: mail, first_name: fn, last_name: ln, password: pw, password_confirmation: pw_conf }
      @valid_user_params.push({ user: params })
      @valid_user_params = @valid_user_params.uniq { |user| user[:user][:email] }
    end
  end
  describe "create" do
    context 'valid normal inputs' do
      it 'returns a 200' do
        @valid_user_params.each do |user_params|
          post "http://localhost:3000/api/v0/user", params: user_params
          expect(response.status).to eq(200)
        end
      end
    end

    context 'invalid inputs' do
      it 'returns a 400 ERR_BLANK for fully missing body' do
        post "http://localhost:3000/api/v0/user"
        expect(response.status).to eq(400)
        expect(JSON.parse(response.body)["user"][0]["error"]).to eq("ERR_BLANK")
      end

      it 'returns a 400 ERR_BLANK for a missing parameter != password' do
        @valid_user_params.each do |user_params|
          # ============ email is missing  ================
          post "http://localhost:3000/api/v0/user", params: user_params[:user].except!(:email)
          expect(response.status).to eq(400)
          expect(JSON.parse(response.body)["user"][0]["error"]).to eq("ERR_BLANK")

          # ========= first_name is missing  ==============
          post "http://localhost:3000/api/v0/user", params: user_params[:user].except!(:first_name)
          expect(response.status).to eq(400)
          expect(JSON.parse(response.body)["user"][0]["error"]).to eq("ERR_BLANK")

          # ========== last_name is missing  ==============
          post "http://localhost:3000/api/v0/user", params: user_params[:user].except!(:last_name)
          expect(response.status).to eq(400)
          expect(JSON.parse(response.body)["user"][0]["error"]).to eq("ERR_BLANK")

          # =========== password is missing  ==============
          post "http://localhost:3000/api/v0/user", params: user_params[:user].except!(:password)
          expect(response.status).to eq(400)
          expect(JSON.parse(response.body)["user"][0]["error"]).to eq("ERR_BLANK")

          # ====== password_confirmation is missing  ======
          post "http://localhost:3000/api/v0/user", params: user_params[:user].except!(:password_confirmation)
          expect(response.status).to eq(400)
          expect(JSON.parse(response.body)["user"][0]["error"]).to eq("ERR_BLANK")
        end
      end
    end

  end

end
