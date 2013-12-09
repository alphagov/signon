require_relative './metrics'
require 'csv'

class NumbersCsv
  def self.generate
    CSV.open("numbers.csv", "w") do |csv|
      Metrics.new.to_a.each { |line| csv << line }
    end
  end
end
