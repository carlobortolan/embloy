# frozen_string_literal: true

# require 'rails_helper'
#
# RSpec.describe "Api::V0::RegistrationControllers" do
#   before :all do
#     # User.delete_all
#     @valid_user_params = []
#     10.times do
#       fn = Faker::Name.first_name
#       ln = Faker::Name.last_name
#       mail = "#{fn}.#{ln}@fake_tests_12345.com"
#       pw = Faker::Job.field
#       pw_conf = pw
#       params = { email: mail, first_name: fn, last_name: ln, password: pw, password_confirmation: pw_conf }
#       @valid_user_params.push({ user: params })
#       @valid_user_params = @valid_user_params.uniq { |user| user[:user][:email] }
#     end
#   end
#
#   describe 'create' do
#     context 'valid normal inputs' do
#       it 'returns a 200' do
#         @valid_user_params.each do |user_params|
#           post "http://localhost:3000/api/v0/user", params: user_params
#           expect(response.status).to eq(200)
#         end
#       end
#     end
#
#     context 'valid abnormal inputs' do
#       it 'returns a 422 for a taken email address' do
#         @valid_user_params.each do |user_params|
#           post "http://localhost:3000/api/v0/user", params: user_params
#           post "http://localhost:3000/api/v0/user", params: user_params
#           expect(response.status).to eq(422)
#           expect(JSON.parse(response.body)["email"][0]["error"]).to eq("ERR_TAKEN")
#         end
#       end
#     end
#
#     context 'invalid inputs' do
#       it 'returns a 400 ERR_BLANK for fully missing body' do
#         post "http://localhost:3000/api/v0/user"
#         expect(response.status).to eq(400)
#         expect(JSON.parse(response.body)["user"][0]["error"]).to eq("ERR_BLANK")
#       end
#
#       it 'returns a 400 ERR_BLANK for a missing parameter != password' do
#         @valid_user_params.each do |user_params|
#           # ============ email is missing  ================
#           params = user_params.deep_dup
#           post "http://localhost:3000/api/v0/user", params: params[:user].except!(:email)
#           expect(response.status).to eq(400)
#           expect(JSON.parse(response.body)["user"][0]["error"]).to eq("ERR_BLANK")
#
#           # ========= first_name is missing  ==============
#           params = user_params.deep_dup
#           post "http://localhost:3000/api/v0/user", params: params[:user].except!(:first_name)
#           expect(response.status).to eq(400)
#           expect(JSON.parse(response.body)["user"][0]["error"]).to eq("ERR_BLANK")
#
#           # ========== last_name is missing  ==============
#           params = user_params.deep_dup
#           post "http://localhost:3000/api/v0/user", params: params[:user].except!(:last_name)
#           expect(response.status).to eq(400)
#           expect(JSON.parse(response.body)["user"][0]["error"]).to eq("ERR_BLANK")
#
#           # =========== password is missing  ==============
#           params = user_params.deep_dup
#           post "http://localhost:3000/api/v0/user", params: params[:user].except!(:password)
#           expect(response.status).to eq(400)
#           expect(JSON.parse(response.body)["user"][0]["error"]).to eq("ERR_BLANK")
#
#           # ====== password_confirmation is missing  ======
#           params = user_params.deep_dup
#           post "http://localhost:3000/api/v0/user", params: params[:user].except!(:password_confirmation)
#           expect(response.status).to eq(400)
#           expect(JSON.parse(response.body)["user"][0]["error"]).to eq("ERR_BLANK")
#         end
#       end
#
#       it 'returns a 400 ERR_BLANK for included claims that are empty' do
#         @valid_user_params.each do |user_params|
#           # ============= email is empty  =================
#           params = user_params.deep_dup
#           params[:user][:email] = ""
#           post "http://localhost:3000/api/v0/user", params: params
#           expect(response.status).to eq(400)
#           expect(JSON.parse(response.body)["email"][0]["error"] || JSON.parse(response.body)["email"][1]["error"]).to eq("ERR_BLANK")
#
#           # =========== first_name is empty  ==============
#           params = user_params.deep_dup
#           params[:user][:first_name] = ""
#           post "http://localhost:3000/api/v0/user", params: params
#           expect(response.status).to eq(400)
#           expect(JSON.parse(response.body)["first_name"][0]["error"]).to eq("ERR_BLANK")
#
#           # ============= last_name is empty ==============
#           params = user_params.deep_dup
#           params[:user][:last_name] = ""
#           post "http://localhost:3000/api/v0/user", params: params
#           expect(JSON.parse(response.body)["last_name"][0]["error"]).to eq("ERR_BLANK")
#
#           # ============= password is empty  ==============
#           params = user_params.deep_dup
#           params[:user][:password] = ""
#           post "http://localhost:3000/api/v0/user", params: params
#           expect(response.status).to eq(400)
#           expect(JSON.parse(response.body)["password"][0]["error"]).to eq("ERR_BLANK")
#
#           # ======= password_confirmation is empty  ======= => Kind of a edge case because there is no logical value to raising an blank pw_conf because it is just not matching to the pw
#           params = user_params.deep_dup
#           params[:user][:password_confirmation] = ""
#           post "http://localhost:3000/api/v0/user", params: params
#           expect(response.status).to eq(400)
#           expect(JSON.parse(response.body)["password_confirmation"][0]["error"]).to eq("ERR_INVALID")
#         end
#       end
#
#       it 'returns a 400 ERR_INVALID for to long passwords' do
#         @valid_user_params.each do |user_params|
#           params = user_params.deep_dup
#           to_long_pw = Faker::Lorem.characters(number: rand(1000..7000))
#           params[:user][:password] = to_long_pw
#           params[:user][:password_confirmation] = params[:user][:password]
#           post "http://localhost:3000/api/v0/user", params: params
#           expect(response.status).to eq(400)
#           expect(JSON.parse(response.body)["password"][0]["error"]).to eq("ERR_INVALID")
#         end
#       end
#
#       it 'returns a 400 ERR_INVALID for mismatching password/password_confirmation' do
#         @valid_user_params.each do |user_params|
#           params = user_params.deep_dup
#           params[:user][:password_confirmation] = "user_params[:user][:password]"
#           post "http://localhost:3000/api/v0/user", params: params
#           expect(response.status).to eq(400)
#           expect(JSON.parse(response.body)["password_confirmation"][0]["error"]).to eq("ERR_INVALID")
#         end
#       end
#
#       it 'returns a 400 ERR_INVALID for malformed email' do
#         @valid_user_params.each do |user_params|
#           params = user_params.deep_dup
#           params[:user][:email] = params[:user][:last_name]
#           post "http://localhost:3000/api/v0/user", params: params
#           expect(response.status).to eq(400)
#           expect(JSON.parse(response.body)["email"][0]["error"]).to eq("ERR_INVALID")
#         end
#       end
#     end
#   end
#
#   describe 'verify' do
#     context 'valid normal inputs' do
#       before :each do
#         User.delete_all
#         @valid_user_params.each do |params|
#           User.create!(params[:user])
#         end
#       end
#       it 'returns a 200' do
#         @valid_user_params.each do |user_params|
#           get "http://localhost:3000/api/v0/user/verify?email=#{user_params[:user][:email]}&password=#{user_params[:user][:password]}"
#           expect(response.status).to eq(200)
#         end
#       end
#     end
#
#
#     context 'valid abnormal inputs' do
#       before :each do
#         User.delete_all
#         @valid_user_params.each do |params|
#           User.create!(params[:user])
#         end
#       end
#
#       it "returns a 401 ERR_INVALID for malformed email and wrong password or both" do
#         @valid_user_params.each do |user_params|
#
#           # ====== either email or password is wrong ======
#           email = 'wrongmail@'
#           get "http://localhost:3000/api/v0/user/verify?email=#{email}&password=#{user_params[:user][:password]}"
#           expect(response.status).to eq(401)
#           expect(JSON.parse(response.body)["email||password"][0]["error"]).to eq("ERR_INVALID")
#
#           password = 'wrongword'
#           get "http://localhost:3000/api/v0/user/verify?email=#{user_params[:user][:email]}&password=#{password}"
#           expect(response.status).to eq(401)
#           expect(JSON.parse(response.body)["email||password"][0]["error"]).to eq("ERR_INVALID")
#
#           # ======== email and password are wrong =========
#           get "http://localhost:3000/api/v0/user/verify?email=#{email}&password=#{password}"
#           expect(response.status).to eq(401)
#           expect(JSON.parse(response.body)["email||password"][0]["error"]).to eq("ERR_INVALID")
#
#         end
#       end
#
#     end
#
#
#     context 'invalid inputs' do
#       before :each do
#         User.delete_all
#         @valid_user_params.each do |params|
#           User.create!(params[:user])
#         end
#       end
#       it 'returns a 400 ERR_BLANK for fully missing email param' do
#         # ====== either email or password are nil =======
#         @valid_user_params.each do |user_params|
#           get "http://localhost:3000/api/v0/user/verify?password=#{user_params[:user][:password]}"
#           expect(response.status).to eq(400)
#           expect(JSON.parse(response.body)["email"][0]["error"]).to eq("ERR_BLANK")
#
#           get "http://localhost:3000/api/v0/user/verify?email=#{user_params[:user][:email]}"
#           expect(response.status).to eq(400)
#           expect(JSON.parse(response.body)["password"][0]["error"]).to eq("ERR_BLANK")
#         end
#
#         # ========= email and password are nil ==========
#           get "http://localhost:3000/api/v0/user/verify"
#           expect(response.status).to eq(400)
#           expect(JSON.parse(response.body)["email"][0]["error"]).to eq("ERR_BLANK")
#           expect(JSON.parse(response.body)["password"][0]["error"]).to eq("ERR_BLANK")
#       end
#
#       it 'returns a 400 ERR_BLANK for included params that are empty' do
#         # ============== email is empty =================
#         @valid_user_params.each do |user_params|
#         email = ""
#         get "http://localhost:3000/api/v0/user/verify?email=#{email}&password=#{user_params[:user][:password]}"
#         expect(response.status).to eq(400)
#         expect(JSON.parse(response.body)["email"][0]["error"]).to eq("ERR_BLANK")
#
#         # ============= password is empty ===============
#         # Todo: go on
#         end
#       end
#     end
#
#   end
#
# end
