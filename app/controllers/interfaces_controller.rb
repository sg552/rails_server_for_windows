
class InterfacesController < ActionController::Base

  def call_socket
    render :json =>  {
			result: 'ok'
		}
  end
end
