Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      get "health", to: "health#index"

      post "transfers", to: "transfers#create"
    end
  end
end