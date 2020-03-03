require_relative "./metrics"
require "numbers/user_segments"
require "csv"

module Numbers
  class NumbersCsv
    def self.generate
      CSV.open("numbers.csv", "w") do |csv|
        Metrics.new.to_a.each { |line| csv << line }
      end

      all_users = User.includes({ application_permissions: :application }, :organisation).to_a
      segments = UserSegments.new(all_users)

      CSV.open("numbers.licensing.csv", "w") do |csv|
        Metrics.new(segments.licensing_users, segments.active_licensing_users).to_a.each { |line| csv << line }
      end

      CSV.open("numbers.non_licensing.csv", "w") do |csv|
        Metrics.new(segments.non_licensing_users, segments.active_non_licensing_users).to_a.each { |line| csv << line }
      end
    end
  end
end
