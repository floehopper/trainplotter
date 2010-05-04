class Event < ActiveRecord::Base

  belongs_to :journey
  belongs_to :station

  validates_presence_of :journey
  validates_presence_of :station
  validates_presence_of :timetabled_at

  default_scope :order => "timetabled_at ASC"

  named_scope :arrivals, :conditions => { :type => %w(Event::Arrival Event::DestinationArrival) }
  named_scope :departures, :conditions => { :type => %w(Event::Departure Event::OriginDeparture) }
  named_scope :origin_departures, :conditions => { :type => "Event::OriginDeparture" }
  named_scope :destination_arrivals, :conditions => { :type => "Event::DestinationArrival" }
  named_scope :at_station, lambda { |station| { :conditions => { :station_id => station.id } } }
  named_scope :timetabled_at, lambda { |time| { :conditions => ["timetabled_at = ?", time] } }
  named_scope :timetabled_on, lambda { |time| { :conditions => ["timetabled_at >= ? AND timetabled_at <= ?", time.beginning_of_day, time.end_of_day] } }
  named_scope :timetabled_within, lambda { |duration| { :conditions => ["timetabled_at >= ? AND timetabled_at <= ?", duration.ago, duration.from_now] } }
  named_scope :timetabled_around, lambda { |time, within| { :conditions => ["timetabled_at >= ? AND timetabled_at <= ?", within.ago(time), within.from_now(time)] } }

end