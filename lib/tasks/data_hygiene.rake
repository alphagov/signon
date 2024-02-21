namespace :data_hygiene do
  desc "Bulk update the organisations associated with users."
  task :bulk_update_organisation, %i[csv_filename] => %i[environment set_current_user] do |_, args|
    unless DataHygiene::BulkOrganisationUpdater.call(args[:csv_filename])
      abort "bulk updating organisations encountered errors"
    end
  end
end
