class AddLatitudeAndLongitudeToStations < ActiveRecord::Migration
  def self.up
    add_column :stations, :latitude, :float
    add_column :stations, :longitude, :float
  end

  def self.down
    remove_column :stations, :longitude
    remove_column :stations, :latitude
  end
end
