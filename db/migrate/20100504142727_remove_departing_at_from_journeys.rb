class RemoveDepartingAtFromJourneys < ActiveRecord::Migration  
  def self.up
    remove_index :journeys, :departing_at
    remove_column :journeys, :departing_at
  end

  def self.down
    add_column :journeys, :departing_at, :datetime
    add_index :journeys, :departing_at
  end
end
