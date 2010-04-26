class PositionsController < ApplicationController

  def create
    journey = Journey.find_by_identifier(params[:journey_id])
    position = journey.positions.create!(params.slice(:latitude, :longitude))
    render :partial => position
  end

end