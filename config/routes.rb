Rails.application.routes.draw do
  resources :orders, only: %i[create show] do
    member do
      post :complete
      post :cancel
    end
  end

  resources :accounts, only: %i[show] do
    member do
      post :deposit
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
