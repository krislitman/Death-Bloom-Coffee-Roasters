Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  # Authentication
  devise_for :users, controllers: {
    registrations: "users/registrations",
    sessions:      "users/sessions",
    passwords:     "users/passwords",
    confirmations: "users/confirmations"
  }

  # Public routes
  root "home#index"

  resources :coffees, only: [:index, :show], param: :slug

  resource  :cart, only: [:show] do
    resources :cart_items, only: [:create, :update, :destroy]
  end

  resource :checkout, only: [:show, :create] do
    get :success
    get :cancel
  end

  # Stripe webhooks (no CSRF — verified via Stripe signature)
  post "/webhooks/stripe", to: "webhooks/stripe#receive"

  # Authenticated user routes
  authenticate :user do
    resources :orders,  only: [:index, :show]
    resource  :account, only: [:show, :edit, :update]
  end

  # Admin namespace
  namespace :admin do
    root "dashboard#index"

    resources :users,      only: [:index, :show, :edit, :update]
    resources :coffees,    except: [:show]
    resources :orders,     only: [:index, :show, :update]
    resources :audit_logs, only: [:index]
  end

  # Flipper UI — protected behind admin constraint
  mount Flipper::UI.app(Flipper) => "/admin/flipper",
        constraints: AdminConstraint.new
end
