Rails.application.routes.draw do
  resources :posts do
    resources :comments
  end
  root "landing#index"
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  get "demo", to: "demo#index"
end
