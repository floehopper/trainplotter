class Event < ActiveRecord::Base

  belongs_to :journey
  belongs_to :station

  validates_presence_of :journey
  validates_presence_of :station
  validates_presence_of :timetabled_at

  default_scope :order => "timetabled_at ASC"

  named_scope :departures, :conditions => { :type => %w(Event::Departure Event::OriginDeparture) }
  named_scope :from_station, lambda { |station| { :conditions => { :station_id => station.id } } }
  named_scope :timetabled_on, lambda { |time| { :conditions => ["timetabled_at >= ? AND timetabled_at <= ?", time.beginning_of_day, time.end_of_day] } }

  HACKED_TIME = Time.zone.parse("2010-04-23 09:00 +01:00")
  named_scope :timetabled_within, lambda { |duration| { :conditions => ["timetabled_at >= ? AND timetabled_at <= ?", duration.ago(HACKED_TIME), duration.from_now(HACKED_TIME)] } }
  
  named_scope :timetabled_around, lambda { |time, within| { :conditions => ["timetabled_at >= ? AND timetabled_at <= ?", within.ago(time), within.from_now(time)] } }

end