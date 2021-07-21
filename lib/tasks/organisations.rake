namespace :organisations do
  desc "Fetch organisations"
  task fetch: :environment do
    include VolatileLock::DSL

    with_lock("signon:organisations:fetch") do
      OrganisationsFetcher.new.call
    end
  end
end
