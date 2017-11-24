
Rails.application.routes.draw do
  resources :books do
    collection do
      get :list
    end
  end
end
