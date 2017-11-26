
Rails.application.routes.draw do
  resources :books do
    collection do
      get :list
    end
  end

  resources :interfaces do
    collection do
      post :call_socket
    end
  end
end
