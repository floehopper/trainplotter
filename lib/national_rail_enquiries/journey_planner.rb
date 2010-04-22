require 'mechanize'
require 'hpricot'

module NationalRailEnquiries

  class JourneyPlanner

    class HpricotParser < WWW::Mechanize::Page
      attr_reader :doc
      def initialize(uri = nil, response = nil, body = nil, code = nil)
        @doc = Hpricot(body)
        super(uri, response, body, code)
      end
    end

    class TimeParser
      def initialize(date)
        @date = date
        @last_time = nil
      end
      def time(hours_and_minutes)
        time = Time.parse("#{hours_and_minutes} #{@date}").in_time_zone
        if @last_time && (time < @last_time)
          @date += 1
          time = Time.parse("#{hours_and_minutes} #{@date}").in_time_zone
        end
        @last_time = time
        time
      end
    end

    def initialize
      @agent = WWW::Mechanize.new
      puts "*** New Session ***"
      @agent.pluggable_parser.html = HpricotParser
      @agent.user_agent_alias = "Mac FireFox"
    end

    def plan(options = {})
      departure_time = nil
      @agent.get("http://www.nationalrail.co.uk/") do |home_page|
        times_page = home_page.form_with(:action => "http://ojp.nationalrail.co.uk/en/s/planjourney/plan") do |form|
          form["jpState"] = "single"
          form["commandName"] = "journeyPlannerCommand"
          form["from.searchTerm"] = options[:from]
          form["to.searchTerm"] = options[:to]
          form["timeOfOutwardJourney.arrivalOrDeparture"] = "DEPART"
          form["timeOfOutwardJourney.monthDay"] = options[:time].strftime("%d/%m/%Y")
          form["timeOfOutwardJourney.hour"] = options[:time].strftime("%H")
          form["timeOfOutwardJourney.minute"] = options[:time].strftime("%M")
          # form["timeOfReturnJourney.arrivalOrDeparture"] = "DEPART"
          # form["timeOfReturnJourney.monthDay"] = "Today"
          # form["timeOfReturnJourney.hour"] = "15"
          # form["timeOfReturnJourney.minute"] = "0"
          form["viaMode"] = "VIA"
          form["via.searchTerm"] = ""
          form["offSetOption"] = "0"
          form["_reduceTransfers"] = "on"
          form["operatorMode"] = "SHOW"
          form["operator.code"] = ""
          form["_lookForSleeper"] = "on"
          form["_directTrains"] = "on"
          form["_includeOvertakenTrains"] = "on"
        end.click_button

        if (times_page.doc/"error-message").any?
          raise (times_page.doc/"error-message").first.inner_text.gsub(/\s+/, " ").strip
        end

        date = Date.parse((times_page.doc/".journey-details span:nth-child(0)").first.inner_text.gsub(/\s+/, " ").gsub(/\+ 1 day/, '').strip)

        (times_page.doc/"table#outboundJourneyTable > tbody > tr:not(.status):not(.changes)").each do |tr|

          if (tr.attributes["class"] == "day-heading")
            date = Date.parse((tr/"th > p > span").first.inner_text.strip)
            puts "New date set: #{date} because date boundary found"
            next
          end

          departure_time = TimeParser.new(date).time((tr/"td.leaving").inner_text.strip)
          departure_time_formatted = departure_time.localtime.strftime("%Y-%m-%d %H:%M")
          unless departure_time > options[:time]
            puts "#{departure_time_formatted} departure skipped because departure time is earlier than the search time"
            next
          end

          unless departure_time.to_date == options[:time].to_date
            puts "#{departure_time_formatted} departure and all subsequent departures skipped because departure time is not on the same day"
            return nil
          end

          number_of_changes = (tr/"td:nth-child(6)").inner_text.strip
          unless number_of_changes == "0"
            puts "#{departure_time_formatted} departure skipped because it has #{number_of_changes} changes"
            next
          end

          anchor = (tr/"a[@id^=journeyOption]").first
          link = times_page.links.detect { |l| l.attributes["id"] == anchor["id"] }
          @agent.transact do
            sleep(2 + 4 * (rand - 0.5))
            details_page = link.click

            description = (details_page.doc/"table#journeyLegDetails tbody tr.lastRow td[@colspan=6] div").first.inner_text.gsub(/\s+/, " ").strip
            origins, destinations = (/from (.*) to (.*)/.match(description)[1,2]).map{ |s| s.split(",").map(&:strip) }

            unless origins.include?(options[:from]) && destinations.include?(options[:to])
              puts "#{departure_time_formatted} departure skipped because expected origin (#{options[:from]}) and destination (#{options[:to]}) are not in origins(#{origins.join(",")}) and destinations (#{destinations.join(",")})"
              next
            end

            parser = TimeParser.new(date)

            events = []
            origin_code = (details_page.doc/"td.origin abbr").inner_html.strip
            departs_at = (details_page.doc/"td.leaving").inner_html.strip
            events << {
              :type => Event::OriginDeparture,
              :station_code => origin_code,
              :timetabled_at => parser.time(departs_at)
            }

            (details_page.doc/".callingpoints table > tbody > tr").each do |tr|
              if (tr/".calling-points").length > 0
                station_code = (tr/".calling-points > a > abbr").inner_html.strip
                arrives_at = (tr/".arrives").inner_html.strip
                departs_at = (tr/".departs").inner_html.strip
                departs_at = arrives_at if arrives_at.present? && departs_at.blank?
                arrives_at = departs_at if arrives_at.blank? && departs_at.present?
                events << {
                  :type => Event::Arrival,
                  :station_code => station_code,
                  :timetabled_at => parser.time(arrives_at)
                }
                events << {
                  :type => Event::Departure,
                  :station_code => station_code,
                  :timetabled_at => parser.time(departs_at)
                }
              end
            end

            destination_code = (details_page.doc/"td.destination abbr").inner_html.strip
            arrives_at = (details_page.doc/"td.arriving").inner_html.strip
            events << {
              :type => Event::DestinationArrival,
              :station_code => destination_code,
              :timetabled_at => parser.time(arrives_at)
            }

            yield(events)
          end
        end
      end
      return departure_time
    rescue => e
      File.open("error.html", "w") { |f| f.write(@agent.current_page.parser.to_html) }
      raise e
    end
  end
end