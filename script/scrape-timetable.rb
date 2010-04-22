#!/usr/bin/env ruby

require File.expand_path(File.join(File.dirname(__FILE__), "..", "config", "environment"))

origins_vs_destinations = {

  # East Coast Trains
  ["York"] => ["Newcastle"],
  ["Newcastle"] => ["Glasgow Central"],
  ["Doncaster"] => ["Glasgow Central"],
  ["Leeds"] => ["Aberdeen"],
  ["London Kings Cross"] => ["Leeds", "Edinburgh", "Glasgow Central", "Newcastle", "Aberdeen", "Inverness", "Hull", "Bradford Forster Square", "Skipton", "York"],
  ["Peterborough", "Leeds", "Newcastle", "Bradford Forster Square", "Hull", "Skipton", "Edinburgh", "Harrogate", "Glasgow Central", "Aberdeen", "Inverness"] => ["London Kings Cross"],
  ["Edinburgh"] => ["Newcastle"],
  ["Aberdeen"] => ["Edinburgh"],
  ["Glasgow Central"] => ["York"],

  # Southeast Trains - High Speed
  ["London St Pancras (Domestic)"] => ["Rochester", "Margate", "Faversham", "Dover Priory", "Ebbsfleet International", "Ramsgate", "Ashford International"],
  ["Ashford International", "Faversham", "Ramsgate", "Dover Priory", "Margate", "Ebbsfleet International", "Rochester"] => ["London St Pancras (Domestic)"]
}

origins_vs_destinations.each do |origins, destinations|
  origins.each do |origin|
    destinations.each do |destination|
      planner = NationalRailEnquiries::JourneyPlanner.new
      puts "#{origin}-#{destination}"
      time = 1.day.from_now.localtime.beginning_of_day
      while time.present?
        puts "Searching for journeys after #{time.strftime("%Y-%m-%d %H:%M")}"
        journey = nil
        last_departure_time = planner.plan(:from => origin, :to => destination, :time => time) do |events|
          departure_time = events.first[:timetabled_at]
          departure_time_formatted = departure_time.localtime.strftime("%Y-%m-%d %H:%M")
          puts "#{departure_time_formatted} *** departure with #{events.length} events found"
          journey = Journey.new(:departing_at => departure_time)
          journey.events = events.map do |event|
            event[:type].new(
              :journey => journey,
              :station => Station.find_by_code(event[:station_code]),
              :timetabled_at => event[:timetabled_at]
            )
          end
          unless journey.save
            puts "#{departure_time_formatted} departure skipped because it is not valid: #{journey.errors.full_messages}"
          end
        end
        time = last_departure_time ? last_departure_time.localtime + 1.minute : nil
      end
    end
  end
end
