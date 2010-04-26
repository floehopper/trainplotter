class JourneysController < ApplicationController
  
  def search
    @stations = Station.all
    @departs_around = Time.current
    @departures = []
    if params[:station_code] && params[:departs_around]
      hour = params[:departs_around][:hour]
      minute = params[:departs_around][:minute]
      today = "2010-04-23" # Date.today
      @departs_around = Time.parse("#{hour}:#{minute} #{today}").in_time_zone
      station = Station.find_by_code(params[:station_code])
      @departures = station.events.departures.timetabled_around(@departs_around, 15.minutes).all(:include => :journey)
    end
    if params[:latitude] && params[:longitude]
      latitude = params[:latitude]
      longitude = params[:longitude]
      within = 10
      @stations = Station.find(:all, :origin => [latitude, longitude], :within => within, :order => "distance ASC")
    end
  end
  
  def index
    # @journey = Journey.new(:events => [Event::OriginDeparture.new, Event::DestinationArrival.new])
    @journeys = Journey.all(:include => { :events => :station })
    @stations = @journeys.map(&:events).flatten.map(&:station).uniq.sort_by(&:name)
    if request.xhr?
      render :partial => "journeys", :layout => false
    end
  end
  
  def departing_soon
    # @journeys = Journey.departing_within(10.minutes).all(:include => { :events => :station })
    # if coords = params[:coords]
    #   stations = Station.find(:all, :origin => coords, :within => 20, :order => "distance ASC")
    #   @journeys = @journeys.select { |j| stations.include?(j.departing_station) }.sort_by { |j| stations.index(j.departing_station) }
    # end
    # if request.xhr?
    #   render :partial => "journeys", :layout => false
    # end
  end

  # def search
  #   origin_departure = Event::OriginDeparture.new(params[:journey][:origin_departure])
  #   destination_arrival = Event::DestinationArrival.new(params[:journey][:destination_arrival])
  #   journey = Journey.new(:events => [origin_departure, destination_arrival])
  #   redirect_to journey_path(journey.generate_identifier)
  # end

  def show
    unless @journey = Journey.find_by_identifier(params[:id])
      @journey = Journey.find_canonical(params[:id])
      redirect_to journey_path(@journey), :status => :moved_permanently
    end
  end

end