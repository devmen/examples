# -*- encoding : utf-8 -*-
Smartsourcing::Application.routes.draw do
  # themes_for_rails

  get '/users/sign_up' => redirect('/user/sign_up') # redirect legacy registration route
  devise_scope :user do
    match '/user/auth/:provider/callback(.:format)' => 'devise/registrations#authorise_provider'
    get "/users/confirmation(_:invite)(_:olduser)_ok" => "devise/confirmations#static", :as => "users_confirmation_ok"
    get "/users/confirmation(_:invite)(_:olduser)_double" => "devise/confirmations#static", :as => "users_confirmation_double"
    get "/users/confirmation(_:invite)_error" => "devise/confirmations#static", :as => "users_confirmation_error"
    get "/users/confirmation_:invite" => "devise/registrations#new", :as => "new_user_invite_confirmation"
    post "/users/confirmation_:invite" => "devise/registrations#create", :as => "user_invite_confirmation"
    post "/users/make" => "devise/registrations#make", :as => "make_user_registration"
  end
  devise_for :user
  resources :users, :except => :new do
    resources :institutions, :only => [:edit, :new, :create, :update, :destroy]
    resources :courses, :only => [:edit, :new, :create, :update, :destroy]
    resources :credentials, :only => [:edit, :new, :create, :update, :destroy]
    resources :jobs, :only => [:edit, :new, :create, :update, :destroy]

    collection {
      post 'recalc_ratings'
      post 'join_community'
      post 'leave_community'
    }
    member {
      get 'edit_skills'; put 'update_skills'
      post 'invite'
    }
  end
  get "members(/:order)(/page/:page)(.:format)" => "members#index", :constraints => { :page => /\d+/ }, :defaults => { :page => 1, :order => 'rating_with_factor' }, :as => :members

  resources :messages, :except => [:edit, :update, :delete]

  get "groups/:group_id(/page/:page)(.:format)" => "posts#index", :constraints => { :page => /\d+/, :group_id => /\d+/ }, :defaults => { :page => 1 }
  resources :groups, :except => :show

  resources :blogs, :except => :show do
    collection {
      get 'collective'
      get 'corporate', :corporate => 'true'
    }
  end
  constraints :id => /\d+/ do
    get "blogs/:blog/:id(.:format)" => "posts#show", :as => :blog_post
    put "blogs/:blog/:id(.:format)" => "posts#update"
    delete "blogs/:blog/:id(.:format)" => "posts#destroy"
  end
  get "blogs/:blog_id(/page/:page)(.:format)" => "posts#index", :constraints => { :page => /\d+/ }, :defaults => { :page => 1 }

  get "posts(/user/:user_id)(/tag/:tag)(/page/:page)(.:format)" => "posts#index", :as => :posts, :constraints => { :page => /\d+/ }, :defaults => { :page => 1 }
  resources :posts do
    resources :comments, :only => :create
    resources :votes, :only => :create
    resources :drafts, :only => :create
    resources :favorites, :only => :create
    get 'search', :on => :collection
    member {
      put 'publish_on_main'
      put 'unpublish_from_main'
      put 'subscribe'
      put 'unsubscribe'
    }
  end

  get "micro_posts(/user/:user_id)(/category/:category_id)(/page/:page)(.:format)" => "micro_posts#index", :as => :micro_posts, :constraints => { :page => /\d+/ }, :defaults => { :page => 1 }
  resources :micro_posts do
    resources :comments, :only => :create
    resources :votes, :only => :create
    resources :drafts, :only => :create
    resources :favorites, :only => :create
    member {
      put 'publish_on_main'
      put 'unpublish_from_main'
      put 'subscribe'
      put 'unsubscribe'
    }
  end

  get "questions(/user/:user_id)(/category/:category_id)(/page/:page)(.:format)" => "questions#index", :as => :questions, :constraints => { :page => /\d+/ }, :defaults => { :page => 1 }
  resources :questions do
    resources :comments, :only => :create
    resources :votes, :only => :create
    resources :drafts, :only => :create
    resources :favorites, :only => :create
    member {
      put 'publish_on_main'
      put 'unpublish_from_main'
      put 'subscribe'
      put 'unsubscribe'
    }
  end

  get "comments(/user/:user_id)(/page/:page)(.:format)" => "comments#index", :as => :comments, :constraints => { :page => /\d+/ }, :defaults => { :page => 1 }
  resources :comments, :only => [:index, :destroy] do
    resources :drafts, :only => :create
    resources :votes, :only => :create
    member { put 'toggle_best' }
  end

  get "drafts(/page/:page)(.:format)" => "drafts#index", :as => :drafts, :constraints => { :page => /\d+/ }, :defaults => { :page => 1 }
  resources :drafts, :only => [:index, :show, :update, :destroy]

  get "favorites(/page/:page)(.:format)" => "favorites#index", :as => :favorites, :constraints => { :page => /\d+/ }, :defaults => { :page => 1 }
  resources :favorites, :only => [:index, :destroy]

  # get counter value
  get 'counter/:type/:id' => 'downloads#counter', :as => :counter

  # CKEditor attachment files extra routes
  mount Ckeditor::Engine => '/ckeditor'
  put '/ckeditor/attachment_files/:id(.:format)' => 'ckeditor/attachment_files#update', :as => :ckeditor_attachment_file, :constraints => { :id => /\d+/ }
  get 'download/:guid' => 'posts#show', :as => :file_download, :defaults => { :id => 'download' }
  get 'downloads' => 'downloads#file'

  # Render partials for SSI include
  get 'partials/:action', :controller => 'partials', :as => :partials

  resources :events do
    collection { get 'accept' }
    member {
      post 'participate'
      post 'invite'
      post 'register'
      post 'export'
    }
  end

  resources :domains
  resources :pages
  resources :references, :except => :show
  resources :settings, :except => :show
  resources :categories, :except => :show
  resources :statuses, :except => :show
  resources :locations, :except => :show
  resources :countries, :except => :show
  resources :templates, :except => :show
  resources :navigations, :except => :show
  resources :services, :except => :show do
    member { put :archive; put :unarchive }
  end

  get 'banner/:place_type/:place_id' => 'downloads#banner', :as => :banner
  get 'banner_click/:banner_id' => 'downloads#banner_click'
  resources :ad_campaigns do
    AdCampaign::ACTIONS.keys.each do |action|
      put action, :on => :member
    end
    resources :banners do
      resources :banner_places do
        BannerPlace::ACTIONS.keys.each do |action|
          put action, :on => :member
        end
      end
    end
  end

  # get "companies/:id/orders/:type(/:state)(/page/:page)(.:format)" => "orders#index", :constraints => { :page => /\d+/ }, :defaults => { :page => 1, :state => 'active' }, :as => :company_orders
  get "companies(/page/:page)(.:format)" => "companies#index", :constraints => { :page => /\d+/ }, :defaults => { :page => 1 }
  resources :companies do
    collection { get 'accept'; put 'update_roles' }
    member { get 'edit_technologies'; post 'invite' }

    resources :projects, :except => :index
    resources :certificates, :except => [:index, :show]
    resources :recommendations, :except => [:index, :show]
    resources :company_services, :except => :index
  end
  get "orders(/page/:page)(.:format)" => "orders#index", :constraints => { :page => /\d+/ }, :defaults => { :page => 1, :state => 'active' }
  resources :orders do
    collection { get 'accept' }
    member { put 'close' }
    resources :offers, :only => :create do
      member { put 'accept'; put 'reject' }
    end
  end
  resources :offers, :only => :create

  get "/.:format" => "posts_feeds#index"
  get "/p/:page(.:format)" => "posts_feeds#index", :constraints => { :page => /\d+/ }
  root :to => 'posts_feeds#index'
end
