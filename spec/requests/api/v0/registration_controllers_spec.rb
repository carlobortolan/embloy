require 'rails_helper'

RSpec.describe "Api::V0::RegistrationControllers" do
  before :all do
    User.delete_all
    @valid_user_params = []
    500.times do
      fn = Faker::Name.first_name
      ln = Faker::Name.last_name
      mail = "#{fn}.#{ln}@fake_tests_12345.com"
      pw = Faker::Job.name
      pw_conf = pw
      params = {email:mail, first_name:fn, last_name:ln, password:pw, password_confirmation:pw_conf}
      @valid_user_params.push({user:params})
      @valid_user_params = @valid_user_params.uniq { |user| user[:user][:email] }
    end
  end
  describe "create user" do

    it 'should return 200' do
      @valid_user_params.each do |user_params|
        expect(response.status).to eq(200)
      end
    end

  end

end
