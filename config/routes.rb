Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"

  resources :users, only: [ :create ] do
    member do
      get :followers
      get :following
    end
  end

  resources :follows, only: [ :create, :destroy ]

  resources :time_clockings, only: [] do
    collection do
      post :clock_in
      patch :clock_out
    end
  end

  get "/users/:user_id/time_records_of_following_list", to: "time_clockings#list_time_records_of_following_list"
end
