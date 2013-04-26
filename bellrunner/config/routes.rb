BellRunner::Application.routes.draw do

  devise_for :users

  resources :tracks, :only => [ :index, :create ] do
    get :download, :on => :collection
    get :link, :on => :member
  end

  resources :home, :only => [:index]
  root :to => "tracks#index"
end
