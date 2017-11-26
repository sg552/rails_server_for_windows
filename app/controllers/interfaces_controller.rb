require 'socket'

class InterfacesController < ActionController::Base

  def call_socket
    printers = ActiveSupport::JSON.decode(params[:socket_ips])
    chosen_dishes = ActiveSupport::JSON.decode(params[:chosen_dishes])
    Rails.logger.info printers.inspect
    Rails.logger.info chosen_dishes.inspect

    printers.each do |printer|

      chosen_dishes.each do |chosen_dish|
        if printer['categoryArray'].include? chosen_dish['category_id']
          print(printer, chosen_dish, params[:table_name])
        end
      end

    end

    render :json =>  {
			result: 'ok',
      socket_ips: socket_ips,
      chosen_dishes: chosen_dishes
		}
  end

  NEW_LINE = "\x0A"
  CUT_PAPER = "\x0A\x0A\x1D\x56\x01"
  DOUBLE_SIZE = "\x1B\x21\x30"

  def print printer, chosen_dish, table_name
    Rails.logger.info "== ticket to print: "
    sleep 0.1
		s = TCPSocket.new(printer['socketIPAddress'], printer['port'])

    sleep 0.1
		# 打印
    s.write DOUBLE_SIZE
    print_line s, "========"
    print_line s, chosen_dish.name
    print_line s, chosen_dish.quantity + "  " + chosen_dish.unit
    print_line s, chosen_dish.comment
    print_line s, "下单时间：#{Time.now.strftime("%Y-%m-%d %H:%M:%S")}"
    print_line s, "桌号： #{table_name}"

		# 切纸
    sleep 0.1
		s.write CUT_PAPER

    sleep 0.1
		s.close

  end

  def print_line socket, string
    Rails.logger.info "== #{string}"
    socket.write string.force_encoding('GBK')
    socket.write NEW_LINE
  end

end
