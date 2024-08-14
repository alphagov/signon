require "csv"

namespace :event_log do
  desc "Delete all events in the event log older than 2 years"
  task delete_logs_older_than_two_years: :environment do
    delete_count = EventLog.where("created_at < ?", 2.years.ago).delete_all
    puts "#{delete_count} event log entries deleted"
  end

  # Run the following, amending the output location/filename based on your
  # system and preference, to get a local CSV output using this Rake task
  #
  # kubectl -n apps exec deploy/signon bundle exec rake 'event_log:get_non_gds_permissions_events_from_last_year' > ~/Downloads/non_gds_permissions_events_from_last_year.csv
  #
  desc "Get permissions-related events for non-GDS users from the last year"
  task get_non_gds_permissions_events_from_last_year: :environment do
    gds_organisation_id = Organisation.find_by(content_id: Organisation::GDS_ORG_CONTENT_ID).id
    non_gds_user_ids = User.where.not(organisation_id: gds_organisation_id).pluck(:id)
    non_gds_user_uids = User.where.not(organisation_id: gds_organisation_id).pluck(:uid)

    event_logs_in_the_last_year = EventLog
      .where(event_id: [EventLog::PERMISSIONS_ADDED.id, EventLog::PERMISSIONS_REMOVED.id])
      .where(initiator_id: non_gds_user_ids)
      .where(uid: non_gds_user_uids) # uid == the uid of the grantee
      .where("created_at >= :date", date: Time.zone.now.ago(1.year))
      .includes(:initiator)

    event_logs_csv = "id,datetime,type,application,permissions,granter_id,granter_email,granter_organisation,granter_role,grantee_id,grantee_email,grantee_organisation,grantee_role\n"

    event_logs_in_the_last_year.find_each do |event_log|
      grantee = User.find_by(uid: event_log.uid)

      event_logs_csv << "#{[
        event_log.id,
        event_log.created_at,
        event_log.event_id == EventLog::PERMISSIONS_ADDED.id ? 'added' : 'removed',
        event_log.application&.name || "#{Doorkeeper::Application.unscoped.retired.find(event_log.application_id).name} (retired)",
        event_log.trailing_message[1..-2].gsub(',', ';'),
        event_log.initiator_id,
        event_log.initiator.email,
        "\"#{event_log.initiator.organisation_name}\"",
        event_log.initiator.role_name,
        grantee.id,
        grantee.email,
        "\"#{grantee.organisation_name}\"",
        grantee.role_name,
      ].join(',')}\n"
    end

    puts event_logs_csv
  end

  desc "Get permissions for non-GDS users added by non-GDS publishing managers"
  task get_permissions_for_non_gds_users_added_by_non_gds_publishing_managers: :environment do
    gds_organisation_id = Organisation.find_by(content_id: Organisation::GDS_ORG_CONTENT_ID).id
    non_gds_publishing_manager_ids = User
      .where.not(organisation_id: gds_organisation_id)
      .where(role: [Roles::OrganisationAdmin.name, Roles::SuperOrganisationAdmin.name])
      .pluck(:id)

    CSV.open("tmp/permissions_by_non_gds_user.csv", "w") do |csv|
      csv << [
        "Grantee ID",
        "Grantee email",
        "Grantee organisation (now)",
        "Grantee role (now)",
        "Grantee status (now)",
        "Application",
        "Permission",
        "Added at",
        "Granter ID",
        "Granter email",
        "Granter organisation (now)",
        "Granter role (now)",
        "EventLog ID",
        "All permissions added during event",
      ]

      User.where.not(organisation_id: gds_organisation_id).find_each do |user|
        event_logs = EventLog
          .where(event_id: EventLog::PERMISSIONS_ADDED.id, uid: user.uid)
          .where(initiator_id: non_gds_publishing_manager_ids)
          .includes(:initiator)
          .order(created_at: :desc)
          .map do |model_instance|
            {
              model_instance:,
              application_id: model_instance.application&.id,
              permission_names: model_instance.trailing_message[1..-2].split(", "),
            }
          end

        user.supported_permissions.pluck(:application_id, :name).each do |application_id, permission_name|
          event_log = event_logs.find { |log| log[:application_id] == application_id && log[:permission_names].include?(permission_name) }

          next unless event_log

          model_instance = event_log[:model_instance]

          csv << [
            user.id,
            user.email,
            "\"#{user.organisation_name}\"",
            user.role_name,
            user.status,
            model_instance.application&.name || "#{Doorkeeper::Application.unscoped.retired.find(model_instance.application_id).name} (retired)",
            permission_name,
            model_instance.created_at,
            model_instance.initiator_id,
            model_instance.initiator.email,
            "\"#{model_instance.initiator.organisation_name}\"",
            model_instance.initiator.role_name,
            model_instance.id,
            model_instance.trailing_message[1..-2].gsub(",", ";"),
          ]
        end
      end
    end
  end
end
