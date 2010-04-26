class AddIdentifierToJourneys < ActiveRecord::Migration
  def self.up
    add_column :journeys, :identifier, :string
    add_index :journeys, :identifier
    Journey.all.each do |journey|
      journey.update_attributes!(:identifier => journey.generate_identifier)
    end
  end

  def self.down
    remove_index :journeys, :identifier
    remove_column :journeys, :identifier
  end
end
