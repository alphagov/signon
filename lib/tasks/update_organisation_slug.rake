desc "Update an organisation slug"
task :update_organisation_slug, [:old_slug, :new_slug] => :environment do |_task, args|
  logger = Logger.new(STDOUT)
  logger.error("You must specify [old_slug,new_slug]") unless args.old_slug.present? && args.new_slug.present?

  exit(1) unless OrganisationSlugUpdater.new(args.old_slug, args.new_slug, logger).call
end
