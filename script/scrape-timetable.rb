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

      aborted = false
      while !aborted
        puts "Searching for journeys after #{time.strftime("%Y-%m-%d %H:%M")}"

        skip_summary = lambda { |departure_time, number_of_changes|
          departure_time_formatted = departure_time.localtime.strftime("%Y-%m-%d %H:%M")
          unless departure_time > time
            puts "#{departure_time_formatted} departure skipped because departure time is earlier than the search time"
            return true
          end
          unless number_of_changes == "0"
            puts "#{departure_time_formatted} departure skipped because it has #{number_of_changes} changes"
            return true
          end
          return false
        }

        abort_summary = lambda { |departure_time|
          departure_time_formatted = departure_time.localtime.strftime("%Y-%m-%d %H:%M")
          unless departure_time.to_date == time.to_date
            puts "#{departure_time_formatted} departure and all subsequent departures skipped because departure time is not on the same day"
            aborted = true
            return true
          end
          return false
        }

        aborted = false
        departure_time = time
        planner.plan(
          :from => origin,
          :to => destination,
          :time => time,
          :skip_summary => skip_summary,
          :abort_summary => abort_summary
        ) do |origins, destinations, stops|
          stop = stops.shift
          departure_time = stop[:departs_at]
          departure_time_formatted = departure_time.localtime.strftime("%Y-%m-%d %H:%M")
          unless origins.include?(origin) && destinations.include?(destination)
            puts "#{departure_time_formatted} departure skipped because expected origin (#{origin}) and destination (#{destination}) are not in origins (#{origins.join(",")}) and destinations (#{destinations.join(",")})"
            break
          end
          puts "#{departure_time_formatted} *** departure with #{stops.length} stops found"
          journey = Journey.new(:departing_at => stop[:departs_at])
          journey.events << Event::OriginDeparture.new(
            :journey => journey,
            :station => Station.find_by_code(stop[:station_code]),
            :timetabled_at => stop[:departs_at]
          )
          while stops.length > 1 do
            stop = stops.shift
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
          stop = stops.shift
          journey.events << Event::DestinationArrival.new(
            :journey => journey,
            :station => Station.find_by_code(stop[:station_code]),
            :timetabled_at => stop[:arrives_at]
          )
          unless journey.save
            puts "#{departure_time_formatted} departure skipped because it is not valid: #{journey.errors.full_messages}"
          end
        end
        time = departure_time.localtime + 1.minute
      end
    end
  end
end
