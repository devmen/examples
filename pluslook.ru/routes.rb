Pluslook::Application.routes.draw do

  resources :promos

  # Rails admin
  mount RailsAdmin::Engine => "/admin"
  # get "/admin/:model_name/:id/edit", :to => RailsAdmin::MainController, :as => :rails_admin_edit


  
  
  # Users and sessions
  get "logout" => "sessions#destroy", :as => "logout"
  get "login"  => "sessions#new",     :as => "login"
  get "signup" => "users#new",        :as => "signup"
  get "password_resets/new"

  match '/auth/:provider/callback' => 'authentications#create'
  match '/auth/failure' => 'authentications#failure'
  resources :authentications

  resources :password_resets
  resources :sessions
  get 'users(/m/:mode)(/p/:page)(.:format)' => 'users#index', :constraints => {:page => /\d+/}, :defaults => {:page => 1, :mode => 'new'}, :as => :users
  resources :users do
    resources :votings, :only => [:create, :destroy]
    resources :subscribes, :only => [:create, :destroy]
    resources :albums, :except => :show
  end

  resources :complaints, :only => [:index, :destroy] do
    collection do
      get :block_all
    end
  end

  get 'galleries/:album_id(/p/:page)(.:format)' => 'looks#index', :as => :album_looks, :constraints => {:page => /\d+/}, :defaults => {:page => 1, :top_menu => 'gallery'}
  get 'users/:user_id/looks(/p/:page)(.:format)' => 'looks#index', :as => :user_looks, :constraints => {:page => /\d+/}, :defaults => {:page => 1, :top_menu => 'user_looks'}

  get 'gallery' => "gallery#index"
  get 'galleries(/:mode)(/p/:page)(.:format)' => 'gallery#index', :as => :galleries, :constraints => {:page => /\d+/, :mode => /[a-z_]+/}, :defaults => {:page => 1, :mode => 'new'}

  get 'looks/embed.html' => 'looks#embed'
  
  get 'looks/search(/:q)(/p/:page)(.:format)' => 'looks#search', :as => :search_looks, :constraints => {:page => /\d+/, :q => /.+/}, :defaults => {:page => 1}
  get 'looks(/:mode)(/p/:page)(.:format)' => 'looks#index', :as => :mode_looks, :constraints => {:page => /\d+/, :mode => /[a-z_]+/}, :defaults => {:page => 1, :mode => 'new'}
  resources :looks, :except => [:new, :create] do
    collection do
      get :random
    end
    member do
      get :face_info
    end
    resources :comments, :only => [:create, :destroy]
    resources :complaints, :only => [:create, :destroy]
    resources :votings, :only => [:create, :destroy]
    resources :look_albums, :only => [:create, :destroy]
  end

  resources :topics, :only => [] do
    resources :complaints, :only => [:create, :destroy]
  end
  
  get 'sites(/m/:mode)(/p/:page)(.:format)' => 'sites#index', :constraints => {:page => /\d+/}, :defaults => {:page => 1, :mode => 'best'}, :as => :sites
  
  resources :sites do
    resources :comments, :only => [:create, :destroy]
    resources :complaints, :only => [:create, :destroy]
    resources :votings, :only => [:create, :destroy]
    resources :subscribes, :only => [:create, :destroy]
  end

  resources :categories
  resources :pages
  resources :parse_logs, :only => :index

  root :to => 'welcome#index'
end
