Clickhotel::Application.routes.draw do
  filter :locale

  namespace :admin do
    resources :hotels, :only => [] do
      member do
        get :locations
        put :update_locations

        get :brouschure
        put :update_brouschure
        delete :brouchure_destroy

        get :services
        put :update_services

      end
      resources :photos, :videos, :rooms, :hotel_room_categories, :arrangements, :hotel_additional_services, :orders
      resources :hotel_room_categories, :only => [] do
        resources :rooms
      end
    end

    resources :rooms, :only => [] do
      resources :photos, :videos
    end

    resources :hotel_room_categories, :only => [] do
      resources :photos, :videos
    end
    resources :arrangements, :only => [] do
      resources :photos, :videos
    end
    resources :hotel_additional_services, :only => [] do
      resources :photos, :videos
    end
    resources :regions, :only => [] do
      resources :photos, :videos
    end
  end
  ActiveAdmin.routes(self)

  # mount RailsAdmin::Engine => '/rails_admin', :as => 'rails_admin'

  devise_for :users

  resources :hotels, :only => [:index, :show] do
    get 'p/:page(.:format)', :action => :index, :on => :collection
    resources :rooms, :only => :index do
      get 'p/:page(.:format)', :action => :index, :on => :collection
    end
    resources :hotel_additional_services, :only => [:index, :show]
    resources :orders, :only => [:new, :create, :show]
  end
  resource :bookings, :only => [:create, :destroy]

  match '/' => 'home#index', :as => 'home'
  root :to => redirect("/#{I18n.default_locale}")
end
