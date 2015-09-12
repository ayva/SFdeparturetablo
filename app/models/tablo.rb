class Tablo

  attr_reader :lon, :lat, :agency, :stops,:departures

  def initialize(ip)
    @base_url="http://webservices.nextbus.com/service/publicXMLFeed?"
    getCoordinates(ip);
  
    @radius=0.004

    #Stores all trasport and stops with location for Northern California
    @agency = {}
    buildAgencies();
    buildRoutes();
    buildStops();

    #Looking for stops within geo radious
    nearbyStops();
    
    #Checking for departures for stops above
    getDepartures(@stops);
    
  end

  def getCoordinates(ip)
    location=JSON.parse(HTTParty.get("http://freegeoip.net/json/"+ip).to_json)
    @lon=location["longitude"]
    @lat=location["latitude"]
  end

  def setCoordinates(ip)
    location = Geokit::Geocoders::IpGeocoder.geocode(ip)
    if !location.longitude.nil? || !location.latitude.nil? || location.longitude!=0 || location.latitude!=0
      @lon=location.longitude
      @lat=location.latitude
    else
      @lon=-122.3117
      @lat=37.9158
    end  
  end

  def getData(str)
    return JSON.parse(HTTParty.get(@base_url+str).to_json)
  end

  def buildAgencies
    all = getData("command=agencyList")
    all["body"]["agency"].each do |agency|
      if agency["regionTitle"]=="California-Northern" 
        #&& agency["tag"]=="emery"
        @agency[agency["tag"]]=agency["title"]
        
        break;
      end
    end
  end

  def buildRoutes
    @agency.keys.each do |key|
      @agency[key]=getData("command=routeList&a="+key)["body"]["route"]
    end
  end

  def buildStops
    @agency.keys.each do |agent|
      @agency[agent].each do |routeTag|
        routeTag["route"]= getData("command=routeConfig&a="+agent+"&r="+routeTag["tag"])["body"]["route"]
      end
    end
  end



  def nearbyStops
    @stops={}
    @agency.keys.each do |agent|
      @stops[agent]={}
      @agency[agent].each do |route|
        @stops[agent][route["route"]["tag"]]={}
        latMax=route["route"]["latMax"].to_f
        latMin=route["route"]["latMin"].to_f
        lonMax=route["route"]["lonMax"].to_f
        lonMin=route["route"]["lonMin"].to_f
        
        #Check if location within whole route coordinates
        if latMax>@lat && latMin<@lat && lonMax>@lon && lonMin<@lon
          

          #If coord within route, looking for stops within radius
          route["route"]["stop"].each do |stop|
            
            if( (stop["lat"].to_f-@radius) < @lat) && (@lat < (stop["lat"].to_f+@radius) )&& ((stop["lon"].to_f-@radius) < @lon) && (@lon < (stop["lon"].to_f+@radius))
              puts agent
              print route["route"]["tag"], stop["tag"]

              @stops[agent][route["route"]["tag"]][stop["tag"]] = true
            
            end
          
          end
        end

      end
    end
      
  end

  def getDepartures(stops)
   
    @stops.keys.each do |agency|
      #We have to get departure for each agency's stops
      str="command=predictionsForMultiStops&"+"a=#{agency}"
      
      @stops[agency].keys.each do |route_tag|
        @stops[agency][route_tag].keys.each do |stopTag|
          str+="&stops=#{route_tag}|#{stopTag}"
        end
      end
      @departures=getData(str)
      
    end
    

  end


  


end