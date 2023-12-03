# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'SubscriptionsController' do
  before(:all) do
    charset = ('a'..'z').to_a + ('A'..'Z').to_a

    ### USER CREATION ###

    # Create valid verified user without own jobs, upcoming jobs, reviews, ...
    @valid_user = User.create!(
      "first_name": "Max",
      "last_name": "Mustermann",
      "email": "#{(0...16).map { charset.sample }.join}@embloy.com",
      "password": "password",
      "password_confirmation": "password",
      "user_role": "verified",
      "activity_status": "1"
    )
    puts "Created verified user without own jobs, upcoming jobs, reviews: #{@valid_user.id}"

    # Create valid verified user with subscriptions
    @valid_user_has_subscriptions = User.create!(
        "first_name": "Max",
        "last_name": "Mustermann",
        "email": "#{(0...16).map { charset.sample }.join}@embloy.com",
        "password": "password",
        "password_confirmation": "password",
        "user_role": "verified",
        "activity_status": "1"
    )
    puts "Created verified user with subscriptions: #{@valid_user_has_subscriptions.id}"
      
    # Create valid unverified user
    @unverified_user = User.create!(
      "first_name": "Max",
      "last_name": "Mustermann",
      "email": "#{(0...16).map { charset.sample }.join}@embloy.com",
      "password": "password",
      "password_confirmation": "password",
      "user_role": "spectator",
      "activity_status": "0"
    )
    puts "Created unverified user: #{@unverified_user.id}"

    # Blacklisted verified user
    @blacklisted_user = User.create!(
      "first_name": "Max",
      "last_name": "Mustermann",
      "email": "#{(0...16).map { charset.sample }.join}@embloy.com",
      "password": "password",
      "password_confirmation": "password",
      "user_role": "verified",
      "activity_status": "1"
    )
    puts "Created blacklisted user: #{@blacklisted_user.id}"

    ### ACCESS / REFRESH TOKENS ###

    # Verified user refresh/access tokens
    credentials = Base64.strict_encode64("#{@valid_user.email}:password")
    headers = { 'Authorization' => "Basic #{credentials}" }
    post '/api/v0/user/auth/token/refresh', headers: headers
    @valid_refresh_token = JSON.parse(response.body)['refresh_token']
    puts "Valid user refresh token: #{@valid_refresh_token}"

    headers = { "HTTP_REFRESH_TOKEN" => @valid_refresh_token }
    post '/api/v0/user/auth/token/access', headers: headers
    @valid_access_token = JSON.parse(response.body)['access_token']
    puts "Valid user access token: #{@valid_access_token}"

    # Verified user with subscriptions refresh/access tokens
    credentials = Base64.strict_encode64("#{@valid_user_has_subscriptions.email}:password")
    headers = { 'Authorization' => "Basic #{credentials}" }
    post '/api/v0/user/auth/token/refresh', headers: headers
    @valid_rt_has_subscriptions = JSON.parse(response.body)['refresh_token']
    puts "Valid user with subscriptions refresh token: #{@valid_rt_has_subscriptions}"

    headers = { "HTTP_REFRESH_TOKEN" => @valid_rt_has_subscriptions }
    post '/api/v0/user/auth/token/access', headers: headers
    @valid_at_has_subscriptions = JSON.parse(response.body)['access_token']
    puts "Valid user access token: #{@valid_at_has_subscriptions}"    

    # Blacklisted user refresh/access/client tokens
    credentials = Base64.strict_encode64("#{@blacklisted_user.email}:password")
    headers = { 'Authorization' => "Basic #{credentials}" }
    post '/api/v0/user/auth/token/refresh', headers: headers
    @valid_rt_blacklisted = JSON.parse(response.body)['refresh_token']
    puts "Valid user who will be blacklisted refresh token: #{@valid_rt_blacklisted}"

    headers = { "HTTP_REFRESH_TOKEN" => @valid_rt_blacklisted }
    post '/api/v0/user/auth/token/access', headers: headers
    @valid_at_blacklisted = JSON.parse(response.body)['access_token']
    puts "Valid user who will be blacklisted access token: #{@valid_at_blacklisted}"

    UserBlacklist.create!(
      "user_id": @blacklisted_user.id,
      "reason": "Test blacklist"
    )
    puts "Blacklisted user #{@blacklisted_user.id}}"

    # Invalid/expired access tokens
    @invalid_access_token = "eyJhbGciOiJIUzI1NiJ9.eyJzdWILOjQ6LCJleHAiOjE2OTgxNzk0MjgsImp0aSI6IjQ1NDMyZWUyNWE4YWUyMjc1ZGY0YTE2ZTNlNmQ0YTY4IiwiaWF0IjoxNjk4MTY1MDI4LCJpc3MiOiJDQl9TdXJmYWNlUHJvOCJ9.nqGgQ6Z52CbaHZzPGcwQG6U-nMDxb1yIe7HQMxjoDTs"
  
    # SUBSCRIPTIONS
    # Create subscriptions for valid verified user (valid_user_has_subscriptions)
    @forbidden_subscription = Subscription.create!(
        user_id: @blacklisted_user.id,
        tier: "basic",
        active: true,
        expiration_date: Time.now,
        start_date: Time.now,
        auto_renew: true,
        start_date: Time.now,
    )  
   @subscription = Subscription.create!(
      user_id: @valid_user_has_subscriptions.id,
      tier: "basic",
      active: true,
      expiration_date: Time.now,
      start_date: Time.now,
      auto_renew: true,
      start_date: Time.now,
    )  

  end

  describe "Subscription", type: :request do
    describe "(GET: /api/v0/client/subscriptions)" do
        context 'valid normal inputs' do
          it 'returns [200 Ok] and JSON job JSONs if user has subscriptions' do
            headers = { "HTTP_ACCESS_TOKEN" => @valid_at_has_subscriptions }
            get '/api/v0/client/subscriptions', headers: headers
            expect(response).to have_http_status(200)
          end
          it 'returns [204 No Content] if user does not have any subscriptions' do
            headers = { "HTTP_ACCESS_TOKEN" => @valid_access_token }
            get '/api/v0/client/subscriptions', headers: headers
            expect(response).to have_http_status(204)
          end
        end
        context 'invalid inputs' do
          it 'returns [400 Bad Request] for missing access token in header' do
            get '/api/v0/client/subscriptions'
            expect(response).to have_http_status(400)
          end
          it 'returns [401 Unauthorized] for expired/invalid access token' do
            headers = { "HTTP_ACCESS_TOKEN" => @invalid_access_token }
            get '/api/v0/client/subscriptions', headers: headers
            expect(response).to have_http_status(401)
          end
          it 'returns [403 Forbidden] for blacklisted user' do
            headers = { "HTTP_ACCESS_TOKEN" => @valid_at_blacklisted }
            get '/api/v0/client/subscriptions', headers: headers
            expect(response).to have_http_status(403)
          end
        end
      end  

    describe "(GET: /api/v0/client/subscriptions/{id})" do
      context 'valid normal inputs' do
        it 'returns [200 Ok] and user JSON' do
          headers = { "HTTP_ACCESS_TOKEN" => @valid_at_has_subscriptions }
          get "/api/v0/client/subscriptions/#{@subscription.id}", headers: headers
          expect(response).to have_http_status(200)
        end
      end
      context 'invalid inputs' do
        it 'returns [400 Bad Request] for missing access token in header' do
          get "/api/v0/client/subscriptions/#{@subscription.id}"
          expect(response).to have_http_status(400)
        end
        it 'returns [401 Unauthorized] for expired/invalid access token' do
          headers = { "HTTP_ACCESS_TOKEN" => @invalid_access_token }
          get "/api/v0/client/subscriptions/#{@subscription.id}", headers: headers
          expect(response).to have_http_status(401)
        end
        it 'returns [403 Forbidden] for blacklisted user' do
          headers = { "HTTP_ACCESS_TOKEN" => @valid_at_blacklisted }
          get "/api/v0/client/subscriptions/#{@subscription.id}", headers: headers
          expect(response).to have_http_status(403)
        end
        it 'returns [404 Not Found] for trying to access someone else\'s submission' do
          headers = { "HTTP_ACCESS_TOKEN" => @valid_at_has_subscriptions }
          get "/api/v0/client/subscriptions/#{@forbidden_subscription.id}", headers: headers
          expect(response).to have_http_status(404)
        end
        it 'returns [404 Not Found] for non existing subscription' do
          headers = { "HTTP_ACCESS_TOKEN" => @valid_at_has_subscriptions }
          get "/api/v0/client/subscriptions/#{@subscription.id+1}", headers: headers
          expect(response).to have_http_status(404)
        end  
      end
    end

    describe "(POST: /api/v0/client/subscriptions)" do
      context 'valid normal inputs' do
        it 'returns [201 Created] and creates new subscription' do
          body = { subscription: {tier: "basic", active: true, expiration_date: "2024-11-19T06:16:09.000Z", start_date: "2024-11-19T06:16:09.000Z", auto_renew: true }}
          post '/api/v0/client/subscriptions', params: body.to_json, headers: { 'Content-Type' => 'application/json', "HTTP_ACCESS_TOKEN" => @valid_access_token }
          expect(response).to have_http_status(201)
        end
      end
      context 'invalid inputs' do
        it 'returns [400 Bad Request] for missing access token' do
          body = { subscription: {tier: "basic", active: true, expiration_date: "2024-11-19T06:16:09.000Z", start_date: "2024-11-19T06:16:09.000Z", auto_renew: true }}
          post '/api/v0/client/subscriptions', params: body.to_json, headers: { 'Content-Type' => 'application/json' }
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for empty header' do
            post '/api/v0/client/subscriptions' 
            expect(response).to have_http_status(400)
        end 
        it 'returns [400 Bad Request] for missing tier' do
          body = { subscription: {active: true, expiration_date: "2024-11-19T06:16:09.000Z", start_date: "2024-11-19T06:16:09.000Z", auto_renew: true }}
          post '/api/v0/client/subscriptions', params: body.to_json, headers: { 'Content-Type' => 'application/json', "HTTP_ACCESS_TOKEN" => @valid_access_token }
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for missing active' do
          body = { subscription: {tier: "basic", expiration_date: "2024-11-19T06:16:09.000Z", start_date: "2024-11-19T06:16:09.000Z", auto_renew: true }}
          post '/api/v0/client/subscriptions', params: body.to_json, headers: { 'Content-Type' => 'application/json', "HTTP_ACCESS_TOKEN" => @valid_access_token }
          expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for missing expiration date' do
            body = { subscription: {tier: "basic", active: true, start_date: "2024-11-19T06:16:09.000Z", auto_renew: true }}
            post '/api/v0/client/subscriptions', params: body.to_json, headers: { 'Content-Type' => 'application/json', "HTTP_ACCESS_TOKEN" => @valid_access_token }
            expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for missing start date' do
          body = { subscription: {tier: "basic", active: true, expiration_date: "2024-11-19T06:16:09.000Z", auto_renew: true }}
            post '/api/v0/client/subscriptions', params: body.to_json, headers: { 'Content-Type' => 'application/json', "HTTP_ACCESS_TOKEN" => @valid_access_token }
            expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for missing auto renew' do
          body = { subscription: {tier: "basic", active: true, expiration_date: "2024-11-19T06:16:09.000Z", start_date: "2024-11-19T06:16:09.000Z" }}
            post '/api/v0/client/subscriptions', params: body.to_json, headers: { 'Content-Type' => 'application/json', "HTTP_ACCESS_TOKEN" => @valid_access_token }
            expect(response).to have_http_status(400)
        end
        it 'returns [400 Bad Request] for invalid tier' do
            body_1 = {subscription: {tier: "test123", active: true, expiration_date: "2024-11-19T06:16:09.000Z", start_date: "2024-11-19T06:16:09.000Z", auto_renew: true }}
            body_2 = {subscription: {tier: "", active: true, expiration_date: "2024-11-19T06:16:09.000Z", start_date: "2024-11-19T06:16:09.000Z", auto_renew: true }}
            body_3 = {subscription: {tier: nil, active: true, expiration_date: "2024-11-19T06:16:09.000Z", start_date: "2024-11-19T06:16:09.000Z", auto_renew: true }}
            post '/api/v0/client/subscriptions', params: body_1.to_json, headers: { 'Content-Type' => 'application/json', "HTTP_ACCESS_TOKEN" => @valid_access_token }
            expect(response).to have_http_status(400)
            post '/api/v0/client/subscriptions', params: body_2.to_json, headers: { 'Content-Type' => 'application/json', "HTTP_ACCESS_TOKEN" => @valid_access_token }
            expect(response).to have_http_status(400)
            post '/api/v0/client/subscriptions', params: body_3.to_json, headers: { 'Content-Type' => 'application/json', "HTTP_ACCESS_TOKEN" => @valid_access_token }
            expect(response).to have_http_status(400)
        end
      end
    end

    describe "(PATCH: /api/v0/client/subscriptions/{id}/activate)" do
        context 'valid normal inputs' do
          it 'returns [200 Ok] and activates subscription' do
            headers = { "HTTP_ACCESS_TOKEN" => @valid_at_has_subscriptions }
            patch "/api/v0/client/subscriptions/#{@subscription.id}/activate", headers: headers
            expect(response).to have_http_status(200)
          end
        end
        context 'invalid inputs' do
          it 'returns [400 Bad Request] for missing access token in header' do
            patch "/api/v0/client/subscriptions/#{@subscription.id}/activate"
            expect(response).to have_http_status(400)
          end
          it 'returns [401 Unauthorized] for expired/invalid access token' do
            headers = { "HTTP_ACCESS_TOKEN" => @invalid_access_token }
            patch "/api/v0/client/subscriptions/#{@subscription.id}/activate", headers: headers
            expect(response).to have_http_status(401)
          end
          it 'returns [403 Forbidden] for blacklisted user' do
            headers = { "HTTP_ACCESS_TOKEN" => @valid_at_blacklisted }
            patch "/api/v0/client/subscriptions/#{@subscription.id}/activate", headers: headers
            expect(response).to have_http_status(403)
          end
          it 'returns [404 Not Found] for trying to activate someone else\'s submission' do
            headers = { "HTTP_ACCESS_TOKEN" => @valid_at_has_subscriptions }
            patch "/api/v0/client/subscriptions/#{@forbidden_subscription.id}/activate", headers: headers
            expect(response).to have_http_status(404)
          end
          it 'returns [404 Not Found] for non existing subscription' do
            headers = { "HTTP_ACCESS_TOKEN" => @valid_at_has_subscriptions }
            patch "/api/v0/client/subscriptions/#{@subscription.id+1}/renew", headers: headers
            expect(response).to have_http_status(404)
          end
        end
      end

      describe "(PATCH: /api/v0/client/subscriptions/{id})/renew" do
        context 'valid normal inputs' do
          it 'returns [200 Ok] and renews subscription' do
            headers = { "HTTP_ACCESS_TOKEN" => @valid_at_has_subscriptions }
            patch "/api/v0/client/subscriptions/#{@subscription.id}/renew", headers: headers
            expect(response).to have_http_status(200)
          end
        end
        context 'invalid inputs' do
          it 'returns [400 Bad Request] for missing access token in header' do
            patch "/api/v0/client/subscriptions/#{@subscription.id}/renew"
            expect(response).to have_http_status(400)
          end
          it 'returns [401 Unauthorized] for expired/invalid access token' do
            headers = { "HTTP_ACCESS_TOKEN" => @invalid_access_token }
            patch "/api/v0/client/subscriptions/#{@subscription.id}/renew", headers: headers
            expect(response).to have_http_status(401)
          end
          it 'returns [403 Forbidden] for blacklisted user' do
            headers = { "HTTP_ACCESS_TOKEN" => @valid_at_blacklisted }
            patch "/api/v0/client/subscriptions/#{@subscription.id}/renew", headers: headers
            expect(response).to have_http_status(403)
          end
          it 'returns [404 Not Found] for trying to renew someone else\'s submission' do
            headers = { "HTTP_ACCESS_TOKEN" => @valid_at_has_subscriptions }
            patch "/api/v0/client/subscriptions/#{@forbidden_subscription.id}/renew", headers: headers
            expect(response).to have_http_status(404)
          end
          it 'returns [404 Not Found] for non existing subscription' do
            headers = { "HTTP_ACCESS_TOKEN" => @valid_at_has_subscriptions }
            patch "/api/v0/client/subscriptions/#{@subscription.id+1}/renew", headers: headers
            expect(response).to have_http_status(404)
          end  
        end
      end
      
      describe "(PATCH: /api/v0/client/subscriptions/{id})/cancel" do
        context 'valid normal inputs' do
            it 'returns [200 Ok] and cancels subscription' do
              headers = { "HTTP_ACCESS_TOKEN" => @valid_at_has_subscriptions }
              patch "/api/v0/client/subscriptions/#{@subscription.id}/cancel", headers: headers
              expect(response).to have_http_status(200)
            end
        end
        context 'invalid inputs' do
            it 'returns [400 Bad Request] for missing access token in header' do
              patch "/api/v0/client/subscriptions/#{@subscription.id}/cancel"
              expect(response).to have_http_status(400)
            end
            it 'returns [401 Unauthorized] for expired/invalid access token' do
              headers = { "HTTP_ACCESS_TOKEN" => @invalid_access_token }
              patch "/api/v0/client/subscriptions/#{@subscription.id}/cancel", headers: headers
              expect(response).to have_http_status(401)
            end
            it 'returns [403 Forbidden] for blacklisted user' do
              headers = { "HTTP_ACCESS_TOKEN" => @valid_at_blacklisted }
              patch "/api/v0/client/subscriptions/#{@subscription.id}/cancel", headers: headers
              expect(response).to have_http_status(403)
            end
            it 'returns [404 Not Found] for trying to cancel someone else\'s submission' do
              headers = { "HTTP_ACCESS_TOKEN" => @valid_at_has_subscriptions }
              patch "/api/v0/client/subscriptions/#{@forbidden_subscription.id}/cancel", headers: headers
              expect(response).to have_http_status(404)
            end
            it 'returns [404 Not Found] for non existing subscription' do
                headers = { "HTTP_ACCESS_TOKEN" => @valid_at_has_subscriptions }
                patch "/api/v0/client/subscriptions/#{@subscription.id+1}/renew", headers: headers
                expect(response).to have_http_status(404)
            end  
        end
      end

      describe "(DELETE: /api/v0/client/subscriptions/{id})" do
        context 'valid normal inputs' do
          it 'returns [200 Ok] and deletes subscription' do
            headers = { "HTTP_ACCESS_TOKEN" => @valid_at_has_subscriptions }
            delete "/api/v0/client/subscriptions/#{@subscription.id}", headers: headers
            expect(response).to have_http_status(200)
          end
        end
        context 'invalid inputs' do
          it 'returns [400 Bad Request] for missing access token in header' do
            delete "/api/v0/client/subscriptions/#{@subscription.id}"
            expect(response).to have_http_status(400)
          end
          it 'returns [401 Unauthorized] for expired/invalid access token' do
            headers = { "HTTP_ACCESS_TOKEN" => @invalid_access_token }
            delete "/api/v0/client/subscriptions/#{@subscription.id}", headers: headers
            expect(response).to have_http_status(401)
          end
          it 'returns [403 Forbidden] for blacklisted user' do
            headers = { "HTTP_ACCESS_TOKEN" => @valid_at_blacklisted }
            delete "/api/v0/client/subscriptions/#{@subscription.id}", headers: headers
            expect(response).to have_http_status(403)
          end
          it 'returns [404 Not Found] for trying to delete someone else\'s submission' do
            headers = { "HTTP_ACCESS_TOKEN" => @valid_at_has_subscriptions }
            delete "/api/v0/client/subscriptions/#{@forbidden_subscription.id}", headers: headers
            expect(response).to have_http_status(404)
          end
          it 'returns [404 Not Found] for non existing subscription' do
            headers = { "HTTP_ACCESS_TOKEN" => @valid_at_has_subscriptions }
            delete "/api/v0/client/subscriptions/#{@subscription.id+1}", headers: headers
            expect(response).to have_http_status(404)
          end  
        end
      end  
    end
  end
