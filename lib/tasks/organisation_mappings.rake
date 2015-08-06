require Rails.root + "lib/organisation_mappings/zendesk_to_signon"

namespace :organisation_mappings do
  desc "Apply organisation mappings from Zendesk to signon users"
  task zendesk_to_signon: :environment do
    users_without_organisations = User.where(organisation_id: nil).count

    OrganisationMappings::ZendeskToSignon.apply

    puts "#{users_without_organisations - User.where(organisation_id: nil).count} users were assigned to organisations."
    puts "#{User.where(organisation_id: nil).count} users still do not belong to any organisation."
  end
end
