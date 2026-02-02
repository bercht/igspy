Rails.application.routes.draw do
  devise_for :users
  
  # Página inicial pública
  root "home#index"

  # API para callbacks do n8n
  namespace :api do
    post "callbacks", to: "callbacks#create"
  end

  # Área administrativa (requer autenticação)
  namespace :admin do
    root "dashboard#index"
    get "dashboard", to: "dashboard#index"
    
    # Configurações do Usuário (API Keys)
    get "settings", to: "settings#edit", as: :settings
    patch "settings", to: "settings#update"
    
    # Página Igspy
    resource :igspy, only: [:show, :create]
    resources :scrapings, only: [:index, :show]

    # Rotas para chat com o assistant
    resources :conversations, only: [:show] do
      resources :messages, only: [:create]
      member do
        post :upload_file
      end
    end
  end
  # Webhooks para integrações externas
  namespace :webhooks do
    post 'transcriptions_completed', to: 'base#transcriptions_completed'
    get 'health', to: 'base#health'
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
end