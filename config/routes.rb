Rails.application.routes.draw do
  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'

  namespace :api do
   namespace :v1 do
     get "health", to: "health#index"

      post "accounts/:id/deposit", to: "accounts#deposit"
      post "accounts/:id/withdraw", to: "accounts#withdraw"
      post "transfers", to: "transfers#create"
      post "register", to: "users#create"
      post "login", to: "auth#login"
      post "accounts", to: "accounts#create"

      get "accounts", to: "accounts#index"
      get "accounts/:id", to: "accounts#show"
      get "profile", to: "users#profile"
      
    end
  end
end
