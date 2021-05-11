namespace :bootstrap do
  # TODO: Replace this with an API.
  desc "Create all resources for bootrapping an environment
    Usage:
      boostrap:all[my-test.publishing.service.gov.uk,my-test-env]
      boostrap:all[integration.publishing.service.gov.uk]
  "
  task :all, %i[public_domain resource_prefix] => :environment do |_, args|
    public_domain = args.public_domain
    raise ArgumentError, "Provide a public_domain!" if public_domain.blank?

    api_users = JSON.parse(File.read("config/api_users.json"))

    Configure::ApiUsers.new(
      public_domain: public_domain,
      namespace: args.resource_prefix,
      resource_name_prefix: resource_name_prefix(args.resource_prefix),
    ).configure!(api_users)
  end
end

def resource_name_prefix(resource_prefix)
  given_prefix = resource_prefix.to_s.strip
  given_prefix.present? ? "[#{given_prefix}] " : nil
end
