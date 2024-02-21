namespace :organisations do
  desc "Fetch organisations"
  task fetch: %i[environment set_current_user] do
    include VolatileLock::DSL

    with_lock("signon:organisations:fetch") do
      OrganisationsFetcher.new.call
    end
  end
end
