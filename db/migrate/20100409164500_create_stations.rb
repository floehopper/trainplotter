class CreateStations < ActiveRecord::Migration
  def self.up
    create_table :stations, :force => true do |t|
      t.string :name
      t.string :code
      t.timestamps
    end
    add_index :stations, :name
    add_index :stations, :code
  end

  def self.down
    remove_index :stations, :code
    remove_index :stations, :name
    drop_table :stations
  end
end
