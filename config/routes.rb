Rails.application.routes.draw do
  get "static_pages/home"
  resource :resume, only: [ :show, :edit, :update ] do
    resources :experiences, except: [ :index, :show ]
    resources :skills, except: [ :index, :show ]
    resources :educations, except: [ :index, :show ]
    resources :projects, except: [ :index, :show ]
  end

  devise_for :users
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  # Public resume sharing route
  get "/r/:slug.pdf", to: "resumes#public_pdf", constraints: { format: :pdf }, as: :public_resume_pdf
  get "/r/:slug", to: "resumes#public", as: :public_resume

  # Defines the root path route ("/")
  root "static_pages#home"
end
