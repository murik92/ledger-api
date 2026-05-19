Rails.application.routes.draw do
  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'
  namespace :api do
    namespace :v1 do
      get "health", to: "health#index"

      post "transfers", to: "transfers#create"
    end
  end
end