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
      time = 1.day.from_now.localtime.beginning_of_day

      finished = false
      while !finished
        planner = NationalRailEnquiries::JourneyPlanner.new
        puts "#{time.to_s(:short)} - search for journeys from #{origin} to #{destination}"

        summary_rows = planner.plan(:from => origin, :to => destination, :time => time)
        summary_rows.each do |summary_row|
          print summary_row.departure_time.localtime.to_s(:short)

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

          sleep(2 + 4 * (rand - 0.5))

          details = summary_row.details
          origins, destinations = details[:origins], details[:destinations]
          unless origins.include?(origin) && destinations.include?(destination)
            puts " - skipped because journey is from #{origins.join(",")} to #{destinations.join(",")}"
            next
          end
          puts " - departure with #{details[:stops].length} stops found"

          journey = Journey.build_from(details)

          unless journey.save
            print summary_row.departure_time.localtime.to_s(:short)
            puts " - journey not valid: #{journey.errors.full_messages}"
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
