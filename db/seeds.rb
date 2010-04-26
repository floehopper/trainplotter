# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#   
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Major.create(:name => 'Daley', :city => cities.first)

# stations = NationalRailEnquiries::Stations.new
# stations.each do |name, code|
#   Station.create!(:name => name, :code => code)
# end

stations = Blueghost::Stations.new
stations.each do |name, code, latitude, longitude|
  if station = Station.find_by_code(code)
    station.update_attributes!(:latitude => latitude, :longitude => longitude)
  else
    puts "Ignoring #{name} (#{code})"
  end
end
