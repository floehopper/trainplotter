class Position < ActiveRecord::Base
  belongs_to :journey
  
  default_scope :order => "created_at ASC"
end