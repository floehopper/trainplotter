class Journey < ActiveRecord::Base

  has_many :events

  has_many :departures, :class_name => "Event::Departure"
  has_many :arrivals, :class_name => "Event::Arrival"
  
  has_many :positions

  validate :must_be_unique_for_date
  validate :must_have_exactly_one_origin_departure
  validate :must_have_exactly_one_destination_arrival

  before_validation :store_identifier

  default_scope :order => "departing_at ASC"

  named_scope :on_same_date_as, lambda { |journey|
    { :conditions => ["departing_at >= ? AND departing_at <= ?", journey.departing_at.beginning_of_day, journey.departing_at.end_of_day] }
  }
  named_scope :departing_within, lambda { |duration|
    { :conditions => ["departing_at >= ? AND departing_at <= ?", duration.ago, duration.from_now] }
  }

  class << self
    
    def build_from(details)
      initial_stop = details[:initial_stop]
      journey = Journey.new(:departing_at => initial_stop[:departs_at])
      journey.events << Event::OriginDeparture.new(
        :journey => journey,
        :station => Station.find_by_code(initial_stop[:station_code]),
        :timetabled_at => initial_stop[:departs_at]
      )
      details[:stops].each do |stop|
        journey.events << Event::Arrival.new(
          :journey => journey,
          :station => Station.find_by_code(stop[:station_code]),
          :timetabled_at => stop[:arrives_at]
        )
        journey.events << Event::Departure.new(
          :journey => journey,
          :station => Station.find_by_code(stop[:station_code]),
          :timetabled_at => stop[:departs_at]
        )
      end
      final_stop = details[:final_stop]
      journey.events << Event::DestinationArrival.new(
        :journey => journey,
        :station => Station.find_by_code(final_stop[:station_code]),
        :timetabled_at => final_stop[:arrives_at]
      )
      journey
    end

    def parse_identifier(identifier)
      origin_code, departure_time, destination_code, arrival_time, departure_date = identifier.split("-")
      origin_station = Station.find_by_code(origin_code)
      departure_date.insert(4, "-").insert(-3, "-")
      departure_time.insert(2, ":")
      departs_at = Time.parse("#{departure_time} #{departure_date}").in_time_zone
      destination_station = Station.find_by_code(destination_code)
      arrival_time.insert(2, ":")
      arrives_at = Time.parse("#{arrival_time} #{departure_date}").in_time_zone
      [origin_station, departs_at, destination_station, arrives_at]
    end

    def find_canonical(identifier)
      origin_station, departs_at, destination_station, arrives_at = parse_identifier(identifier)
      departure_events = Event.departures.at_station(origin_station).timetabled_at(departs_at)
      arrival_events = Event.arrivals.at_station(destination_station).timetabled_at(arrives_at)
      journeys_in_common = departure_events.map(&:journey) & arrival_events.map(&:journey)
      case journeys_in_common.length
        when 0 then raise ActiveRecord::RecordNotFound, "No journey found for identifier: #{identifier}"
        when 1 then return journeys_in_common.first
        else raise "Multiple journeys found for identifier: #{identifier} which matches: #{journeys_in_common.map(&:identifier).inspect}"
      end
    end

  end

  def origin_departures
    events.select { |e| Event::OriginDeparture === e }
  end

  def origin_departure
    origin_departures.first
  end

  def origin_station
    origin_departure.station
  end

  def departs_at
    origin_departure.timetabled_at.localtime
  end

  def departs_on
    origin_departure.timetabled_at.localtime.to_date
  end

  def destination_arrivals
    events.select { |e| Event::DestinationArrival === e }
  end

  def destination_arrival
    destination_arrivals.first
  end

  def destination_station
    destination_arrival.station
  end

  def arrives_at
    destination_arrival.timetabled_at.localtime
  end

  def to_param
    identifier
  end

  def generate_identifier
    [
      origin_station.code,
      departs_at.to_s(:short_time),
      destination_station.code,
      arrives_at.to_s(:short_time),
      departs_on.to_s(:number)
    ].join("-")
  end

  def each_stop
    events.group_by(&:station).each do |station, events|
      arrives_at = events.detect { |e| Event::Arrival === e }.try(:timetabled_at).try(:localtime)
      departs_at = events.detect { |e| Event::Departure === e }.try(:timetabled_at).try(:localtime)
      yield(station, arrives_at, departs_at)
    end
  end

  private

  def store_identifier
    self.identifier = generate_identifier
  end

  def must_be_unique_for_date
    if Journey.on_same_date_as(self).map(&:identifier).include?(generate_identifier)
      errors.add_to_base("must be unique for date")
    end
  end

  def must_have_exactly_one_origin_departure
    unless origin_departures.length == 1
      errors.add_to_base("must have exactly one origin departure")
    end
  end

  def must_have_exactly_one_destination_arrival
    unless destination_arrivals.length == 1
      errors.add_to_base("must have exactly one destination arrival")
    end
  end
end