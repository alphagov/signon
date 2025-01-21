namespace :data_hygiene do
  desc "Bulk update the organisations associated with users."
  task :bulk_update_organisation, %i[csv_filename] => :environment do |_, args|
    unless DataHygiene::BulkOrganisationUpdater.call(args[:csv_filename])
      abort "bulk updating organisations encountered errors"
    end
  end

  desc "Mark an organisation as closed"
  task :close_organisation, %i[content_id] => :environment do |_, args|
    organisation = Organisation.find_by(content_id: args[:content_id])
    organisation.update!(closed: true)
    puts "Marked organisation #{organisation.slug} as closed"
  end
end
