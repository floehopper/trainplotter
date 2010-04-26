class DeparturesController < ApplicationController

  def index
    events = Event.departures
    if station_id = params[:station_id]
      station = Station.find(station_id)
      events = events.from_station(station)
    end
    if params[:today]
      events = events.timetabled_on(Time.zone.parse("2010-04-16 09:30 +01:00"))
    end
    respond_to do |format|
      format.json { render :json => events.map { |e| e.timetabled_at.localtime.to_s(:short_time) } }
    end
  end
  
  def soon
    @departures = Event.departures.timetabled_within(15.minutes).all(:include => [:station, :journey])
    if (latitude = params[:latitude]) && (longitude = params[:longitude])
      stations = Station.find(:all, :origin => [latitude, longitude], :within => 20, :order => "distance ASC")
      @departures = @departures.select { |d| stations.include?(d.station) }.sort_by { |d| stations.index(d.station) }
    end
    if request.xhr?
      render :partial => "departures", :layout => false
    end
  end

end