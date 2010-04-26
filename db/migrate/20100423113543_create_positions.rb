class CreatePositions < ActiveRecord::Migration
  def self.up
    create_table :positions, :force => true do |t|
      t.integer :journey_id
      t.float :latitude
      t.float :longitude
      t.timestamps
    end
  end

  def self.down
    drop_table :positions
  end
end
