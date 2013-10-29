namespace :organisations do
  desc "Fetch organisations from Whitehall"
  task :fetch => :environment do
    OrganisationsFetcher.new.call
  end
end
