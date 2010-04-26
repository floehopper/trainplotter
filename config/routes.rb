ActionController::Routing::Routes.draw do |map|
  map.resources :journeys, :only => [:index, :show], :collection => { :search => :get } do |journeys|
    journeys.resources :positions, :only => [:create]
  end
  map.resources :stations, :only => [:index], :collection => { :nearby => :get }
end
