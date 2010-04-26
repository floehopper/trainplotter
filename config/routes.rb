ActionController::Routing::Routes.draw do |map|
  map.resources :journeys, :collection => { :search => :get, :departing_soon => :get }, :has_many => :positions
  map.resources :stations, :collection => { :nearby => :get }
end
