# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
Rails.application.routes.draw do
  Healthcheck.routes(self)
  devise_for :admins
  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  root to: 'welcome#index'

  # -----> OAUTH CALLBACKS <-----
  get 'auth/github/callback', to: 'oauth_callbacks#github', as: :auth_github_callback
  get 'auth/google_oauth2/callback', to: 'oauth_callbacks#google', as: :auth_google_callback
  get 'auth/azure_activedirectory_v2/callback', to: 'oauth_callbacks#azure', as: :auth_azure_callback
  get 'auth/linkedin/callback', to: 'oauth_callbacks#linkedin', as: :auth_linkedin_callback
  # get 'auth/callback', to: 'integrations/lever/oauth#callback', as: :auth_lever_callback # <= TODO: Temporary route - move to integrations namespace
  get 'auth/lever/callback', to: 'integrations/lever/oauth#callback', as: :auth_lever_callback

  #= <<<<< *INTEGRATIONS* >>>>>>
  get 'api/v0/integrations/lever/auth', to: 'integrations/lever/oauth#authorize', as: :auth_lever
  # get 'api/v0/integrations/lever/callback', to: 'lever_oauth#callback', as: :auth_lever_callback # <= TODO: Update Lever OAuth app callback URI
  post 'api/v0/webhooks/:source/:id', to: 'hooks/webhooks#handle_event', as: :webhook_handler

  #= <<<<< *API* >>>>>>
  namespace :api, defaults: { format: 'json' } do
    namespace :v0 do
      # -----> STATIC RESOURCES & DOCUMENTS <-----
      get 'docs', to: 'static#redirect_to_docs'

      # -----> PASSWORDS <-----
      patch 'user/password', to: 'passwords#update'
      post 'user/password/reset', to: 'password_resets#create'
      patch 'user/password/reset', to: 'password_resets#update', as: :password_reset_update

      # -----> AUTH <-----
      post 'auth/token/refresh', to: 'authentications#create_refresh'
      post 'auth/token/access', to: 'authentications#create_access'
      post 'auth/token/client', to: 'quicklink#create_client'
      post 'auth/token/otp', to: 'authentications#create_otp'
      patch 'auth/token/otp', to: 'authentications#verify_otp'

      # -----> TOKENS <-----
      resources :tokens, only: %i[index create update destroy]

      # -----> USER <-----
      get 'user', to: 'user#show'
      post 'user', to: 'registrations#create'
      patch 'user', to: 'user#edit'
      delete 'user', to: 'user#destroy'
      get 'user/verify', to: 'registrations#verify'
      get 'user/activate', to: 'registrations#activate', as: :activate_account
      post 'user/activate', to: 'registrations#reactivate'
      get 'user/jobs', to: 'user#own_jobs'
      get 'user/applications', to: 'user#own_applications'
      get 'user/reviews', to: 'user#own_reviews'
      get 'user/upcoming', to: 'user#upcoming'
      delete 'user/image', to: 'user#remove_image'
      post 'user/image', to: 'user#upload_image'
      get 'user/events', to: 'user#events'
      get 'user/preferences', to: 'user#preferences'
      patch 'user/preferences', to: 'user#update_preferences'
      get 'user/notifications', to: 'notifications#show'
      get 'user/notifications/unread', to: 'notifications#unread_applications'
      patch 'user/notifications/(/:id)', to: 'notifications#mark_as_read'
      get 'user/webhooks', to: 'webhooks#index'
      post 'user/webhooks/:source', to: 'webhooks#refresh'

      post 'user/(/:id)/reviews', to: 'reviews#create'
      delete 'user/(/:id)/reviews', to: 'reviews#destroy'
      patch 'user/(/:id)/reviews', to: 'reviews#update'

      # -----> JOB-LISTS <-----
      resources :job_lists, only: %i[index create show update destroy] do
        resources :job_list_items, path: 'items', only: %i[create destroy]
      end

      # -----> JOBS <-----
      get 'jobs', to: 'jobs#feed'
      get 'jobs/(/:id)', to: 'jobs#show'
      get 'maps', to: 'jobs#map'
      get 'find', to: 'jobs#find'
      post 'jobs', to: 'jobs#create'
      patch 'jobs', to: 'jobs#update'
      delete 'jobs/(/:id)', to: 'jobs#destroy'
      get 'applications', to: 'applications#show_all'
      get 'jobs/(/:id)/applications', to: 'applications#show'
      get 'jobs/(/:id)/application', to: 'applications#show_single'
      get 'jobs/(/:id)/applications/(/:application_id)', to: 'applications#show_single'
      get 'jobs/(/:id)/application/pipeline', to: 'applications#pipeline'
      get 'jobs/(/:id)/applications/(/:application_id)/pipeline', to: 'applications#pipeline'
      post 'jobs/(/:id)/applications', to: 'applications#create'
      patch 'jobs/(/:id)/applications/(/:application_id)/accept', to: 'applications#accept'
      patch 'jobs/(/:id)/applications/(/:application_id)/reject', to: 'applications#reject'
      post 'jobs/sync/:source', to: 'jobs#synchronize'

      # -----> COMPANIES <-----
      resources :company, only: %i[show create update destroy] do
        resources :teams, only: %i[index create show update destroy]
      end
      get 'company/(/:id)/board', to: 'company#board'
      get 'company/(/:id)/board/(/:job_slug)', to: 'company#job'

      # -----> QUICKLINK <-----
      post 'sdk/request/auth/token', to: 'quicklink#create_request'
      post 'sdk/request/auth/proxy', to: 'quicklink#create_request_proxy'
      post 'sdk/request/handle', to: 'quicklink#handle_request'
      post 'sdk/apply', to: 'quicklink#apply'

      # -----> GENIUS-QUERIES <-----
      get 'resource/(/:genius)', to: 'genius_queries#query'
      post 'resource', to: 'genius_queries#create'

      # -----> SUBSCRIPTIONS <-----
      get 'client/subscriptions', to: 'subscriptions#all_subscriptions'
      get 'client/subscriptions/active', to: 'subscriptions#active_subscription'
      get 'client/subscriptions/charges', to: 'subscriptions#all_charges'

      # -----> STRIPE-PAY <-----
      post 'checkout', to: 'checkouts#show'
      get 'checkout/subscription/success', to: 'checkouts#subscriptionsuccess'
      get 'checkout/payment/success', to: 'checkouts#paymentsuccess'
      get 'checkout/failure', to: 'checkouts#failure'
      get 'billing', to: 'checkouts#billing'
      get 'checkout/portal', to: 'checkouts#portal'
    end
  end
end
# rubocop:enable Metrics/BlockLength
