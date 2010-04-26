class CreateEvents < ActiveRecord::Migration
  def self.up
    create_table :events, :force => true do |t|
      t.string :type
      t.integer :journey_id
      t.integer :station_id
      t.datetime :timetabled_at
      t.timestamps
    end
    add_index :events, :journey_id
    add_index :events, :station_id
    add_index :events, :timetabled_at
  end

  def self.down
    remove_index :events, :timetabled_at
    remove_index :events, :station_id
    remove_index :events, :journey_id
    drop_table :events
  end
end
