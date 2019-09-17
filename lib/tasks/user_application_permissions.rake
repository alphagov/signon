namespace :users do
  desc "Grant 2i reviewer permission in Collections Publisher"
  task grant_2i_reviewer_permission: :environment do
    application = Doorkeeper::Application.find_by(name: "Collections Publisher")
    users = User.where(email: user_emails)

    users.each do |user|
      if user.has_access_to?(application)
        puts "-- Adding 2i reviewer permission for #{user.name} in #{application.name}"
        user.grant_application_permission(application, "2i reviewer")
      else
        puts "-- Granting access for #{user.name} to #{application.name}"
        user.grant_application_permissions(application, ["signin", "GDS Editor", "2i reviewer"])
      end

      if application.supports_push_updates?
        PermissionUpdater.perform_later(user.uid, application.id)
      end
    end
  end

  def user_emails
    %w(
      abigail.waraker@digital.cabinet-office.gov.uk
      ale.delcueto@digital.cabinet-office.gov.uk
      alistair.smith@digital.cabinet-office.gov.uk
      andrew.harsant@digital.cabinet-office.gov.uk
      andy.keen@digital.cabinet-office.gov.uk
      dave.standen@digital.cabinet-office.gov.uk
      gavan.curley@digital.cabinet-office.gov.uk
      george.mcdonald@digital.cabinet-office.gov.uk
      graeme.claridge@digital.cabinet-office.gov.uk
      hannah.mackay@digital.cabinet-office.gov.uk
      hannah.whittaker@digital.cabinet-office.gov.uk
      helen.nickols@digital.cabinet-office.gov.uk
      joe.harrison@digital.cabinet-office.gov.uk
      jon.sanger@digital.cabinet-office.gov.uk
      katherine.dunn@digital.cabinet-office.gov.uk
      kati.tirbhowan@digital.cabinet-office.gov.uk
      lucy.hartley@digital.cabinet-office.gov.uk
      lucy.musselwhite@digital.cabinet-office.gov.uk
      marian.foley@digital.cabinet-office.gov.uk
      matt.clear@digital.cabinet-office.gov.uk
      patricia.turk@digital.cabinet-office.gov.uk
      paula.stephenson@digital.cabinet-office.gov.uk
      polly.green@digital.cabinet-office.gov.uk
      richard.furlong@digital.cabinet-office.gov.uk
      sean.walsh@digital.cabinet-office.gov.uk
      sharon.giles@digital.cabinet-office.gov.uk
      sheryll.sulit@digital.cabinet-office.gov.uk
      stefan.nicolaou@digital.cabinet-office.gov.uk
      stephen.gill@digital.cabinet-office.gov.uk
      tom.hughes@digital.cabinet-office.gov.uk
    )
  end
end
