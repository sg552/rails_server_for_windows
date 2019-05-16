
Rails.application.routes.draw do
  resources :interfaces do
    collection do
      post :call_socket
      post :print_change_table
      post :return_dish
    end
  end


  # map.connect 'interfaces/print_change_table', :controller => 'interfaces', :action => 'print_change_table'
  # map.connect 'interfaces/call_socket', :controller => 'interfaces', :action => 'call_socket'
  # map.connect 'interfaces/return_dish', :controller => 'interfaces', :action => 'return_dish'
  # map.connect 'interfaces/hi', :controller => 'interfaces', :action => 'hi'
end
