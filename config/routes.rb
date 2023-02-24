Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # >>>>>> *API* <<<<<<
  namespace :api, defaults: { format: 'json' } do
    namespace :v0 do
      post 'user', to: 'registrations#create'
      get 'user/verify', to: 'registrations#verify'
      post 'user/auth/token/refresh', to: 'authentications#create_refresh'
      post 'user/auth/token/access', to: 'authentications#create_access'
    end
  end

  # <<<<< *Web-Application* >>>>>>
  # -----> Homepage <-----
  root 'welcome#index', as: :welcome
  get 'about', :to => 'welcome#about', as: :about
  get 'about/privacy/policy', :to => 'welcome#privacy_policy', as: :privacy_policy
  get 'about/privacy/cookies', :to => 'welcome#cookies', as: :cookies
  get 'about/help', :to => 'welcome#help', as: :help
  get 'about/api', :to => 'welcome#api', as: :api
  get 'about/api/apidoc.json', :to => 'welcome#apidoc', as: :apidoc
  get 'about/faq', :to => 'welcome#faq', as: :faq

  # namespace :admin do
  # -----> Jobs & Applications (#TODO: Server / Admin-namespace only ) <-----
  resources :jobs do
    resources :applications
  end
  get 'jobs/(/:job_id)/applications/(/:application_id)/accept', :to => 'applications#accept', as: :job_application_accept
  get 'jobs/(/:job_id)/applications/(/:application_id)/reject', :to => 'applications#reject', as: :job_application_reject
  get 'jobs/(/:job_id)/applications_reject_all', :to => 'applications#reject_all', as: :job_applications_reject_all
  delete 'jobs/(/:job_id)/applications/(/:application_id)' => 'applications#destroy'

  get 'reviews', :to => 'reviews#index', as: :reviews
  get 'reviews/(/:user_id)', :to => 'reviews#for_user', as: :reviews_user
  post 'reviews', :to => 'reviews#index'
  # end
  # -----> Feed-Generator <-----
  get 'find_jobs', :to => 'jobs#find', as: :jobs_find
  post 'find_jobs', :to => 'jobs#parse_inputs'

  # -----> Authentication & Authorization <-----
  get 'sign_up', to: 'registrations#new'
  post 'sign_up', to: 'registrations#create'
  get 'sign_in', to: 'sessions#new'
  post 'sign_in', to: 'sessions#create', as: :log_in
  delete 'logout', to: 'sessions#destroy'

  get 'password', to: 'passwords#edit', as: :edit_password
  patch 'password', to: 'passwords#update'
  get 'password/reset', to: 'password_resets#new'
  post 'password/reset', to: 'password_resets#create'
  get 'password/reset/edit', to: 'password_resets#edit'
  patch 'password/reset/edit', to: 'password_resets#update'

  # -----> User management <-----
  get 'profile', :to => 'profile#index', as: :profile_index
  get 'profile/settings', :to => 'profile#settings', as: :profile_settings
  get 'profile/edit', :to => 'profile#edit', as: :profile_edit

  get 'user/applications', :to => 'applications#own_applications', as: :own_applications
  get 'user/jobs', :to => 'jobs#own_jobs', as: :own_jobs
end
