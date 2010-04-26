require 'OSM/API'

api = OSM::API.new("http://api.openstreetmap.org/api/0.6/")
api.get_way(5065008)
api.get_relation(278268)
