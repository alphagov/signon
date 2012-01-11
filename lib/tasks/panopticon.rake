require 'ostruct'

namespace :panopticon do
  desc "Register application metadata with panopticon"
  task :register => :environment do
    require 'gds_api/panopticon'
    logger = GdsApi::Base.logger = Logger.new(STDERR).tap { |l| l.level = Logger::INFO }
    logger.info "Registering with panopticon..."
    
    registerer = GdsApi::Panopticon::Registerer.new(owning_app: "calendars")
    calendars = {
      bank_holidays: "UK Bank Holidays",
      daylight_saving: "When do the clocks change?"
    }
    
    calendars.each do |slug, title|
      record = OpenStruct.new(slug: slug, title: title)
      registerer.register(record)
    end
  end
end