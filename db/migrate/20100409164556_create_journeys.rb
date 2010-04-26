class CreateJourneys < ActiveRecord::Migration
  def self.up
    create_table :journeys, :force => true do |t|
      t.datetime :departing_at
      t.timestamps
    end
    add_index :journeys, :departing_at
  end

  def self.down
    remove_index :journeys, :departing_at
    drop_table :journeys
  end
end
