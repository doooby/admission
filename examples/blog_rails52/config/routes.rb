Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  scope controller: 'public' do
    root action: 'index'
    post :login
    post :logout
  end
  
  resources :articles, except: %i[index] do
    member do
      post :create_message
    end
  end
  resources :users, except: %i[index show] 

end
