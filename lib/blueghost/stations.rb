require 'mechanize'
require 'hpricot'

module Blueghost

  class Stations

    def each
      # http://bbc.blueghost.co.uk/earth/stations_all.kml
      # => http://bbc.blueghost.co.uk/earth/stations.kmz
      # => http://bbc.blueghost.co.uk/earth/stations.kml
      File.open(File.join(File.dirname(__FILE__), "stations.kml")) do |file|
        doc = Hpricot(file)
        (doc/"kml/Document/Folder/Folder/Placemark").each do |placemark|
          if ((placemark/"styleurl") || (placemark/"styleUrl")).inner_text == "#railStation"
            name = (placemark/"name").inner_text
            description = (placemark/"description").inner_text
            code = /summary.aspx\?T\=([A-Z]{3})\"/.match(description)[1]
            longitude, latitude = (placemark/"point/coordinates").inner_text.split(",").map(&:to_f)
            yield(name, code, latitude, longitude)
          end
        end
      end
    end

  end

end