Rails.application.routes.draw do
  resource :session
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  patch "position", to: "positions#update"
  resources :foci, only: %i[index new create edit update] do
    member do
      patch :restore
    end
  end
  resources :notes, only: %i[index show create edit update destroy] do
    get :export, on: :collection
  end
  get "library", to: "library#index"
  get "random", to: "random_readings#show", as: :random
  get "collections/:collection/random", to: "random_readings#show", as: :random_collection
  get "works/:work/random", to: "random_readings#show", as: :random_work
  resources :collections, only: :show, param: :slug
  resources :works, only: :show, param: :slug
  get "read/:slug/:section(/:number)", to: "readings#show", as: :reading

  root "home#index"
end
