# frozen_string_literal: true

Rails.application.routes.draw do
  root 'log_entries#index'

  resources :log_entries, only: %i[index show create] do
    post :analyze, on: :member
  end

  resource :settings, only: %i[show update] do
    post :restore_default
  end

  get 'up', to: 'rails/health#show', as: :rails_health_check
end
