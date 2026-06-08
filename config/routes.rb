# config/routes.rb

Rails.application.routes.draw do
  mount Rswag::Ui::Engine => "/api-docs"
  mount Rswag::Api::Engine => "/api-docs"

  namespace :api do
    namespace :v1 do
      resources :expenses, only: [:create]
      resources :incomes, only: [:create]

      resources :categories,
          only: [
            :index,
            :create,
            :update,
            :destroy
          ]

      get "health", to: "health#index"

      post "accounts/:id/deposit", to: "accounts#deposit"
      post "accounts/:id/withdraw", to: "accounts#withdraw"

      post "transfers", to: "transfers#create"

      # Authentication
      post "register", to: "users#create"
      post "login", to: "auth#login"

      # Refresh Tokens (Task 15)
      post "auth/refresh", to: "auth#refresh"
      post "auth/logout", to: "auth#logout"
      
      # Email Confirmation (Task 16)
      post "auth/confirm", to: "auth#confirm"
      
      # Password Reset (Task 17)
      post "auth/password_reset", to: "auth#password_reset"
      post "auth/reset_password", to: "auth#reset_password"
      
      # Accounts
      post "accounts", to: "accounts#create"

      get "accounts", to: "accounts#index"
      get "accounts/:id", to: "accounts#show"

      # User profile
      get "profile", to: "users#profile"
    end
  end
end
