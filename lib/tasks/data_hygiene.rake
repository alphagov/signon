namespace :data_hygiene do
  desc "Bulk update the organisations associated with users."
  task :bulk_update_organisation, %i[csv_filename] => :environment do |_, args|
    unless DataHygiene::BulkOrganisationUpdater.call(args[:csv_filename])
      abort "bulk updating organisations encountered errors"
    end
  end
end
