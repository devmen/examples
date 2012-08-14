Carousel::Application.routes.draw do
  resources :images do
    post :evaluate, on: :member
  end

  root :to => 'images#index'
end
