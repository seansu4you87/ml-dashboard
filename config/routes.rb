MobileLearnDashboard::Application.routes.draw do

  devise_for :users

  root to: 'home#index'

  get "/purchases"  => 'home#purchases'

end
