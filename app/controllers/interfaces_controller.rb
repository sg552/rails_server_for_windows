# encoding: utf-8
require 'socket'
class InterfacesController < ActionController::Base
  
  attr_accessor :printed_at

  def hi
    render :json => {
      :result =>  'okok'
    }
  end

  def return_dish

    # 为了解决跨域问题
    headers['Access-Control-Allow-Origin']='*'
    headers['Access-Control-Allow-Methods']='POST, PUT, DELETE, GET, OPTIONS'
    headers['Access-Control-Request-Method']='*'
    headers['Access-Control-Allow-Headers']='Origin, X-Requested-With, Content-Type, Accept, Authorization'

    printer_ips = params[:printer_ips].split(',')
    port = params[:port]    
    table_name = params[:table_name].force_encoding("UTF-8")
    dish_name = params[:dish_name].force_encoding("UTF-8")
    count = params[:count]


    printer_ips.each { | printer_ip| 
      sleep 0.1
      s = TCPSocket.new(printer_ip, port)
      sleep 0.1
      # 调整字体成为2倍大小，并且打印分割线
      s.write DOUBLE_SIZE_FOR_NUMBER + "="
      s.write DOUBLE_SIZE_FOR_CHINESE + "=" * 23

      # 开始打印内容
      print_line s, "退菜"
      print_line s, Time.now.strftime("%Y-%m-%d %H:%M:%S")
      print_line s, "桌号：#{table_name}"      
      print_line s, "菜品名称： #{dish_name}"      
      print_line s, "退菜数量： #{count}"      
      print_line s, "-" * 24

      # 切纸
      sleep 0.1
      s.write CUT_PAPER

      sleep 0.1
      s.close

    }

  end

  # 打印换桌信息 
  def print_change_table

    # 为了解决跨域问题
    headers['Access-Control-Allow-Origin']='*'
    headers['Access-Control-Allow-Methods']='POST, PUT, DELETE, GET, OPTIONS'
    headers['Access-Control-Request-Method']='*'
    headers['Access-Control-Allow-Headers']='Origin, X-Requested-With, Content-Type, Accept, Authorization'

    # 正文开始。
    printer_ips = params[:printer_ips].split(',')
    port = params[:port]
    from_table_name = params[:from_table_name].force_encoding("UTF-8")
    to_table_name = params[:to_table_name].force_encoding("UTF-8")


    printer_ips.each { | printer_ip| 
      sleep 0.1
      s = TCPSocket.new(printer_ip, port)
      sleep 0.1
      # 调整字体成为2倍大小，并且打印分割线
      s.write DOUBLE_SIZE_FOR_NUMBER + "="
      s.write DOUBLE_SIZE_FOR_CHINESE + "=" * 23

      # 开始打印内容
      print_line s, "换桌"  # 注意这里不能为后面加上  .to_s.encode('gbk', 'utf-8')  否则报错。
      print_line s, Time.now.strftime("%Y-%m-%d %H:%M:%S")
      print_line s, "原桌号：#{from_table_name}"
      print_line s, "新桌号：#{to_table_name}"  # .force_encoding("UTF-8").encode('gbk', 'utf-8')
      print_line s, "-" * 24

      # 切纸
      sleep 0.1
      s.write CUT_PAPER

      sleep 0.1
      s.close

    }

    render :json =>  {
      result: 'ok',
      from_table_name: from_table_name,
      to_table_name: to_table_name
    }    
  end 

  # 打印菜品
  def call_socket

    # 为了解决跨域问题
    headers['Access-Control-Allow-Origin']='*'
    headers['Access-Control-Allow-Methods']='POST, PUT, DELETE, GET, OPTIONS'
    headers['Access-Control-Request-Method']='*'
    headers['Access-Control-Allow-Headers']='Origin, X-Requested-With, Content-Type, Accept, Authorization'

    # 正文开始。
    printers = ActiveSupport::JSON.decode(params[:socket_ips])
    temp_chosen_dishes = ActiveSupport::JSON.decode(params[:chosen_dishes])
    chosen_dishes = sort_by_dish_category_id(temp_chosen_dishes)

    @dish_categories = ActiveSupport::JSON.decode(params[:dish_categories])
    @chosen_categories = get_chosen_categories(chosen_dishes, @dish_categories)
    Rails.logger.info printers.inspect
    Rails.logger.info chosen_dishes.inspect

    @printed_at = Time.now
    @table_name = params[:table_name].force_encoding("UTF-8")
    @comment = params[:comment].force_encoding("UTF-8")

    printers.each do |printer|

      if printer['printType'] == 1 
        print_complete_ticket(printer, chosen_dishes, @table_name)

      else 
        print_sub_ticket(printer, chosen_dishes, @table_name, @chosen_categories)
      end
    end

    render :json =>  {
      result: 'ok',
      socket_ips: printers,
      chosen_dishes: chosen_dishes
    }
  end

  NEW_LINE = "\x0A"
  CUT_PAPER = NEW_LINE * 6 + "\x1D\x56\x01"
  DOUBLE_SIZE_FOR_CHINESE = "\x1C\x21\x0C"
  DOUBLE_SIZE_FOR_NUMBER = "\x1B\x21\x30"

  # 做好啦。git add.comment....
  def print_complete_ticket printer, chosen_dishes, table_name
    ip = printer['socketIPAddress']
    port = printer['port']
    is_print_all = printer['printType']
    Rails.logger.info "== ticket to print: #{ip}:#{port}"
    sleep 0.1
    s = TCPSocket.new(ip, port)

    sleep 0.1
    # 调整字体成为2倍大小，并且打印分割线
    s.write DOUBLE_SIZE_FOR_NUMBER + "="
    s.write DOUBLE_SIZE_FOR_CHINESE + "=" * 23

    # 开始打印内容
    print_line s, "皇后镇餐厅总单"
    print_line s, "桌号：#{table_name}"
    print_line s, "#{@printed_at.strftime("%Y-%m-%d %H:%M:%S")}"
    print_line s, "餐厅前台下单"
    formatted_total_comment = @comment.blank? ? "无" : @comment
    print_line s, "整单备注: #{formatted_total_comment}"
    print_line s, "-" * 24
    print_line s, "菜品:" 
    chosen_dishes.each do |chosen_dish|
      Rails.logger.info "== chosen_dish : #{chosen_dish.inspect}"
      formatted_comment = chosen_dish['comment'].blank? ? 
        '' : 
        "(#{chosen_dish['comment']})"
      print_line s, "#{chosen_dish['name']}  X #{chosen_dish['quantity']} #{formatted_comment}"
    end
    print_line s, "-" * 24

    # 切纸
    sleep 0.1
    s.write CUT_PAPER

    sleep 0.1
    s.close

  end

  def print_sub_ticket printer, chosen_dishes, table_name, chosen_categories
    ip = printer['socketIPAddress']
    port = printer['port']
    is_print_all = printer['printType']
    Rails.logger.info "== ticket to print: #{ip}:#{port}"
    sleep 0.1
    s = TCPSocket.new(ip, port)

    sleep 0.1
    
    # 调整字体成为2倍大小，并且打印分割线
    s.write DOUBLE_SIZE_FOR_NUMBER + "="
    s.write DOUBLE_SIZE_FOR_CHINESE + "=" * 23

    # 开始打印分单内容， 每个菜品的分类，打印一个单子
    printer['categoryHashArray'].each do |category_with_name|
      chosen_categories.each do |chosen_category_id|
        next if category_with_name['id'] != chosen_category_id
        print_line s, category_with_name['name']
        print_line s, "桌号：#{table_name}"
        print_line s, Time.now.strftime("%Y-%m-%d %H:%M:%S")

        formatted_total_comment = @comment.blank? ? "无" : @comment
        print_line s, "由餐厅前台下单"
        print_line s, "备注: #{formatted_total_comment}"
        print_line s, NEW_LINE

        print_line s, "菜品:" 
        chosen_dishes.each do |chosen_dish|
          Rails.logger.info "== chosen_dish : #{chosen_dish.inspect}"
          formatted_comment = chosen_dish['comment'].blank? ? 
            '' : 
            "(#{chosen_dish['comment']})"
          if chosen_dish['category_id'] == category_with_name['id']
            print_line s, "#{chosen_dish['name']}  X #{chosen_dish['quantity']} #{formatted_comment}"
          end
        end
        # 切纸
        sleep 0.1
        s.write CUT_PAPER
        sleep 0.1
      end
    end

    sleep 0.1
    s.close
  end

  def sort_by_dish_category_id(chosen_dishes)
    sorted_result = chosen_dishes.sort {  |x, y| 
      temp = x['category_id'] - y['category_id'] 
      Rails.logger.info "== in sort , temp : #{temp}"

      # result = case temp
      # when temp < 0 then -1 
      # when temp > 0 then 1 
      # else 0 
      # end

      if(temp < 0)
        result = -1
      elsif temp > 0 
        result = 1
      else 
        result = 0
      end

      Rails.logger.info "== in sort , result : #{result}"
      result
    }

    Rails.logger.info "== sorted : #{sorted_result.inspect}"
    return sorted_result
  end

  def print_line socket, string
    Rails.logger.info "== #{string}"
    socket.write string.to_s.encode('gbk', 'utf-8')
    socket.write NEW_LINE
  end

  def get_chosen_categories chosen_dishes, all_dish_categories
    result = []
    chosen_dishes.each {  |chosen_dish|
      unless result.include? chosen_dish['category_id']
        result << chosen_dish['category_id']
      end 
    }
    Rails.logger.info "== chosen_categories: #{result.inspect}"
    return result
  end

end
