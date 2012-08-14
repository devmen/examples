class Ranking < ActiveRecord::Base
  attr_accessible :image_id, :rating

  belongs_to :image
end
