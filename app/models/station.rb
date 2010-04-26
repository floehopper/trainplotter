class Station < ActiveRecord::Base

  acts_as_mappable :lat_column_name => :latitude, :lng_column_name => :longitude

  has_many :events
  has_many :journeys, :through => :events

  validates_presence_of :name
  validates_presence_of :code

  # it would be nice to validates_presence_of longitude & latitude
  # but we need to get a comprehensive data set
  # and change the way db:seed works

  default_scope :order => "code ASC"
  
  def google_map_url
    "http://maps.google.co.uk/maps?q=#{latitude},#{longitude}"
  end

end