class AverageCalculator
  def self.calculate(array)
    return 0 unless array.present?
    (array.inject(:+) / array.count.to_f).round(2)
  end
end
