Rails.application.routes.draw do
  resources :blog, controller: "articles", as: "articles", param: :slug

  namespace :admin do
    get "/", to: "dashboard#index", as: :dashboard
    get "/feedbacks", to: "dashboard#feedbacks", as: :dashboard_feedbacks
    get "/resumes", to: "dashboard#resumes", as: :dashboard_resumes
    get "/users", to: "dashboard#users", as: :dashboard_users
  end

  get "static_pages/home"
  get "pricing", to: "static_pages#pricing", as: :pricing

  post "checkout", to: "checkouts#create", as: :checkout
  get "checkout/success", to: "checkouts#success", as: :success_checkout
  get "checkout/cancel", to: "checkouts#cancel", as: :cancel_checkout

  post "webhooks/stripe", to: "webhooks#stripe", as: :stripe_webhook

  post "/guest_sign_up", to: "guest_users#create", as: "guest_sign_up"

  # Use a more explicit route structure to avoid conflicts
  resources :experiences, except: [ :index, :show ]
  resources :skills, except: [ :index, :show ]
  resources :educations, except: [ :index, :show ]
  resources :projects, except: [ :index, :show ]
  resource :resume, only: [ :show, :edit, :update, :destroy ] do
    get :analyze
    get :analytics
  end
  resources :resumes, only: [ :index, :create, :destroy ], param: :slug do
    post :switch, on: :member
    get :analytics, on: :member, as: :analytics_for
  end
  resources :feedbacks, only: [ :create ]

  devise_for :users, controllers: {
    registrations: "users/registrations"
  }

  # Guest user upgrade routes - wrapped in devise_scope for proper Devise mapping
  devise_scope :user do
    put "/users/upgrade", to: "users/registrations#upgrade", as: :upgrade_guest_user
    get "/users/upgrade", to: "users/registrations#upgrade_form", as: :upgrade_guest_user_form
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # PWA files - served as static files
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  # Public resume sharing route
  get "/r/:slug.pdf", to: "resumes#public_pdf", as: :public_resume_pdf, constraints: { slug: /[^\/]+/ }
  get "/r/:slug/download.pdf", to: "resumes#public_pdf_download", as: :public_resume_pdf_download, constraints: { slug: /[^\/]+/ }
  get "/r/:slug", to: "resumes#public", as: :public_resume

  # PDF health check
  get "/pdf-health", to: "resumes#pdf_health_check", as: :pdf_health_check

  # Test PDF generation
  get "/test-pdf", to: "resumes#test_pdf", as: :test_pdf
  get "/test-prawn-pdf", to: "resumes#test_prawn_pdf", as: :test_prawn_pdf

  # PDF diagnostic (no PDF generation)
  get "/pdf-diagnostic", to: "resumes#pdf_diagnostic", as: :pdf_diagnostic

  # Sitemap for SEO
  get "sitemap.xml", to: "application#sitemap", defaults: { format: "xml" }

  # Resume wizard routes
  get "/resume_wizard", to: redirect("/resume_wizard/summary"), as: :resume_wizard_root
  get "/resume_wizard/:id", to: "resume_wizard#show", as: :resume_wizard
  put "/resume_wizard/:id", to: "resume_wizard#update"

  # Defines the root path route ("/")
  root "static_pages#home"
end
