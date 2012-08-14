class Image < ActiveRecord::Base
  RANKS = { 1 => "one", 2 => "two", 3 => "three", 4 => "four", 5 => "five" }
  attr_accessible :url

  has_many :rankings, dependent: :destroy

  validate :url, presence: true, uniqueness: true

  def rate(rank)
    rankings.create(rating: rank)
  end

  def average_rank
    return nil unless rankings.present?
    AverageCalculator.calculate rankings.pluck(:rating)
  end

  def self.average_rank
    AverageCalculator.calculate self.all.map(&:average_rank).compact
  end
end
