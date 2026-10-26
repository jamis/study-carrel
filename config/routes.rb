Rails.application.routes.draw do
  resource :session
  get "join/:token", to: "signups#new", as: :join
  post "join/:token", to: "signups#create"
  namespace :admin do
    resources :invitations, only: %i[index create] do
      patch :revoke, on: :member
    end
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  patch "position", to: "positions#update"
  get "continue", to: "continuations#show"
  resources :foci, only: %i[index new create edit update destroy] do
    get :archived, on: :collection
    member do
      patch :make_current
      patch :archive
      patch :unarchive
      get :delete # a page saying which focus is about to be deleted and what goes with it, before it is
    end
    # Every focus has its notes page, the current one's or a past one's, where they're reread one at a time. Notes on
    # the focus as a whole (free notes) are written there: new and show are their editors, create and update their
    # autosave.
    resources :notes, only: %i[index new create show update] do
      get :export, on: :collection
      resources :labels, only: %i[create destroy], controller: "note_labels"
    end
    # Where the reread of its notes left off (show is the old address of the notes page).
    resource :reread, only: %i[show update]
    # Naming a label (or an unnamed group of notes), or renaming it, from the reread.
    resources :labels, only: :update
    resource :scratchpad, only: :update
    # A passage's note under this focus, written from the reader while another focus is current.
    resources :units, only: [] do
      resource :note, only: %i[show update], controller: "unit_notes"
    end
  end
  resources :units, only: [] do
    resource :note, only: %i[show update], controller: "unit_notes"
    # The reader's picker of other focuses to note this passage under.
    resources :foci, only: :index, controller: "unit_foci"
    resource :keep, only: %i[create update destroy]
  end
  get "notes", to: "notes#current" # the old address of the current focus's notes
  get "history", to: "history#index"
  get "kept", to: "keeps#index"
  # Keeps with no passage, written on the Kept page.
  resources :ideas, only: %i[create update destroy], path: "kept/ideas"
  get "library", to: "library#index"
  get "search", to: "searches#show"
  get "random", to: "random_readings#show", as: :random
  get "collections/:collection/random", to: "random_readings#show", as: :random_collection
  get "works/:work/random", to: "random_readings#show", as: :random_work
  # A user's own texts. Adding one is new > review (which can go back to new with the text) > create; revising one is
  # edit > review > update.
  get "texts/random", to: "random_readings#show", defaults: { texts: "yours" }, as: :random_texts
  resources :texts, only: %i[index new create edit update destroy], param: :slug, controller: "user_texts" do
    post :review, on: :collection
    match :review, on: :member, via: %i[post patch] # the revision's form is a PATCH, and "Edit the text" posts it here
  end
  resources :detached_notes, only: :destroy
  # A user's shelves: works and collections grouped to roll Random and search in. "Put on a shelf…" on a work or
  # collection page adds or takes off one thing (shelf_items, keyed "work-12" or "collection-3").
  resources :shelves, only: %i[show new create edit update destroy], param: :slug do
    resource :item, only: %i[create destroy], controller: "shelf_items"
  end
  get "shelves/:shelf/random", to: "random_readings#show", as: :random_shelf
  resources :collections, only: :show, param: :slug
  resources :works, only: :show, param: :slug
  get "read/:slug/:section(/:number)", to: "readings#show", as: :reading

  root "home#index"
end
