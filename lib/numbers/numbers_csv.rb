require_relative './metrics'
require 'csv'

class NumbersCsv
  extend Metrics

  def self.generate
    CSV.open("numbers.csv", "w") do |csv|
      Metrics.instance_methods(false).each do |metric|
        send(metric).each {|result| csv << ([metric.to_s.humanize, result].flatten) }
      end
    end
  end

end
