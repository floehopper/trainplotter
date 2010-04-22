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
      puts "#{origin}-#{destination}"
      time = 1.day.from_now.localtime.beginning_of_day

      finished = false
      while !finished
        planner = NationalRailEnquiries::JourneyPlanner.new
        puts "Searching for journeys after #{time.strftime("%Y-%m-%d %H:%M")}"

        summary_rows = planner.plan(:from => origin, :to => destination, :time => time)
        summary_rows.each do |summary_row|
          departure_time_formatted = summary_row.departure_time.localtime.strftime("%Y-%m-%d %H:%M")
          print departure_time_formatted

          unless summary_row.departure_time > time
            puts " - skipped because departure time is earlier than the search time"
            next
          end
          unless summary_row.departure_time.to_date == time.to_date
            puts " - aborting because departure time is not on the same day"
            finished = true
            break
          end
          unless summary_row.number_of_changes == "0"
            puts " - skipped because it has #{summary_row.number_of_changes} changes"
            next
          end

          details = summary_row.details
          unless details[:origins].include?(origin) && details[:destinations].include?(destination)
            puts " - skipped because origin & destination are not in origins (#{details[:origins].join(",")}) & destinations (#{details[:destinations].join(",")})"
            next
          end
          puts " - departure with #{details[:stops].length} stops found"

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
          unless journey.save
            puts "#{departure_time_formatted} departure skipped because it is not valid: #{journey.errors.full_messages}"
          end
        end

        if summary_rows.empty?
          time += 1.minute
        else
          time = summary_rows.last.departure_time.localtime + 1.minute
        end
      end
    end
  end
end
