class JourneysController < ApplicationController

  def index
    @journeys = Journey.all(:include => { :events => :station })
  end

  def show
    unless @journey = Journey.find_by_identifier(params[:id])
      @journey = Journey.find_canonical(params[:id])
      redirect_to journey_path(@journey), :status => :moved_permanently
    end
  end

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

end