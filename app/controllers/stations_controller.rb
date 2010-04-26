class StationsController < ApplicationController

  def index
    @stations = Station.all
  end
  
  def nearby
    latitude = params[:latitude]
    longitude = params[:longitude]
    within = params[:within] || 10
    @stations = Station.find(:all, :origin => [latitude, longitude], :within => within, :order => "distance ASC")
    render :json => @stations.to_json
  end

end