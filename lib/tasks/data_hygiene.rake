namespace :data_hygiene do
  desc "Bulk update the organisations associated with users."
  task :bulk_update_organisation, %i(csv_filename) => :environment do |_, args|
    DataHygiene::BulkOrganisationUpdater.call(args[:csv_filename])
  end
end
