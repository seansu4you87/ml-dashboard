MobileLearnDashboard::Application.routes.draw do

  devise_for :users

  root to: 'home#index'

  get "/hours"  => 'home#hours'

end
