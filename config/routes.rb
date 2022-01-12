Rails.application.routes.draw do
  resources :posts 
  post "comment", to: "comments#create", as: :create_comment
  root "landing#index"
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  get "demo", to: "demo#index"
end
