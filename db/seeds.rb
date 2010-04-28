# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#   
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Major.create(:name => 'Daley', :city => cities.first)

puts "Creating stations with names and codes"
stations = NationalRailEnquiries::Stations.new
stations.each do |name, code|
  if station = Station.find_by_code(code)
    puts "#{name} (#{code}) already exists"
  else
    Station.create!(:name => name, :code => code)
  end
end

puts "Adding station latitudes and longitudes"
stations = Blueghost::Stations.new
stations.each do |name, code, latitude, longitude|
  if station = Station.find_by_code(code)
    station.update_attributes!(:latitude => latitude, :longitude => longitude)
  else
    puts "#{name} (#{code}) not found"
  end
end

puts "Adding missing station latitudes and longitudes"
Station.find_by_code("SFA").update_attributes!(
  :latitude => 51.5445797, :longitude => -0.0097182
)
Station.find_by_code("EBD").update_attributes!(
  :latitude => 51.4428002, :longitude => 0.3209516
)