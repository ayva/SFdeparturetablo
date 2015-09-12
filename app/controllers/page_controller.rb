class PageController < ApplicationController

  def index
    @client_ip = find_ip
    @locate=city_state_for_index_info
    
    @departures=Tablo.new(@client_ip).departures
  
  end


  private

  def locate_by_ip
    request.location
  end

  def address_from_ip
    if locate_by_ip && locate_by_ip.address != "Reserved"
        return locate_by_ip.address
    end
  end

  def city_state_for_index_info
    if address_from_ip
      city = locate_by_ip.city
      state = locate_by_ip.state
      return "#{city},#{state}"
    else
      return "San-Francisco, CA"
    end
  end
  
  def find_ip
    if request.remote_ip == '127.0.0.1' || request.remote_ip=='::1'
      # Hard coded remote address
      return "208.113.83.165"
      #NY '123.45.67.89'
    else
      return request.remote_ip
    end
  end

  def address_from_ip
    if locate_by_ip && locate_by_ip.address != "Reserved"
        return locate_by_ip.address
    end
  end
end
