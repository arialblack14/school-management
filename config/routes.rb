Rails.application.routes.draw do

  root to: 'visitors#index'
  namespace :timetable do
    resources :rooms
  end
  devise_for :logins
  resources :people, except: :index do
    resource(:login, only: %i(new create)) { patch :toggle }
    collection do
      get :managers
      get :teachers
      get :students
    end
  end
  resources :courses do
    match :generate_logins, via: [:get, :patch], on: :member
  end

  resources :timetables, only: [:index, :show]
  resources :internship_positions, only: [:index, :show]
  resources :candidates do
    member do
      # patch :init
      patch :accept
      get :reject
    end
  end

end
