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

    def plan(options = {}, &block)
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
          number_of_changes = (tr/"td:nth-child(6)").inner_text.strip

          next if options[:skip_summary] && options[:skip_summary].call(departure_time, number_of_changes)
          break if options[:abort_summary] && options[:abort_summary].call(departure_time)

          anchor = (tr/"a[@id^=journeyOption]").first
          link = times_page.links.detect { |l| l.attributes["id"] == anchor["id"] }
          @agent.transact do
            sleep(2 + 4 * (rand - 0.5))
            parse_details(link.click, date, &block)
          end
        end
      end
    rescue => e
      File.open("error.html", "w") { |f| f.write(@agent.current_page.parser.to_html) }
      raise e
    end

    def parse_details(page, date, &block)
      description = (page.doc/"table#journeyLegDetails tbody tr.lastRow td[@colspan=6] div").first.inner_text.gsub(/\s+/, " ").strip
      origins, destinations = (/from (.*) to (.*)/.match(description)[1,2]).map{ |s| s.split(",").map(&:strip) }
      parser = TimeParser.new(date)

      stops = []
      origin_code = (page.doc/"td.origin abbr").inner_html.strip
      departs_at = (page.doc/"td.leaving").inner_html.strip
      stops << {
        :station_code => origin_code,
        :departs_at => parser.time(departs_at)
      }

      (page.doc/".callingpoints table > tbody > tr").each do |tr|
        if (tr/".calling-points").length > 0
          station_code = (tr/".calling-points > a > abbr").inner_html.strip
          arrives_at = (tr/".arrives").inner_html.strip
          departs_at = (tr/".departs").inner_html.strip
          departs_at = arrives_at if arrives_at.present? && departs_at.blank?
          arrives_at = departs_at if arrives_at.blank? && departs_at.present?
          stops << {
            :station_code => station_code,
            :arrives_at => parser.time(arrives_at),
            :departs_at => parser.time(departs_at)
          }
        end
      end

      destination_code = (page.doc/"td.destination abbr").inner_html.strip
      arrives_at = (page.doc/"td.arriving").inner_html.strip
      stops << {
        :station_code => destination_code,
        :arrives_at => parser.time(arrives_at)
      }

      block.call(origins, destinations, stops)
    rescue => e
      File.open("details-error.html", "w") { |f| f.write(page.parser.to_html) }
      raise e
    end

  end
end