namespace :recent_users do
  desc "Email recent users regarding upcoming migration to Platform 1"
  task :migration_email => :environment do

    class MigrationEmail < ActionMailer::Base
      def notification_email(user)
        to = user.email
        mail(to: to,
             from: "platform-1-migration@govuk.zendesk.com",
             reply_to: "platform-1-migration@govuk.zendesk.com",
             subject: "Planned maintenance starting 25 March 2014",
             content_type: "text/html",
             body: "The GOV.UK Infrastructure Team will be doing planned maintenance from 6pm GMT on Tue, 25 Mar 2014 until 9am GMT on Wed, 26 Mar 2014.\n\nYou will be unable to use Signon or any of the applications that depend on it--including all publishing tools--during this time.\n\nThis work is being done to move GOV.UK's primary hosting onto a new, improved platform, and it requires that we disable all backend applications for a period of time while the migration is taking place.\n\nWhile government users of our publishing applications will be affected as detailed above, there will be very little impact for public users.  At this time, the only disruption we anticipate is that users will be unable to initiate a new license application during the migration period.\n\nIf you have questions about this planned outage, you can reply directly to this message, and a member of the GOV.UK User Support team will respond within five business days.\n\n\n\nThank you,\n\n\nGOV.UK Infrastructure Team"
            )
      end
    end

    User.last_signed_in_after(90.days.ago).each do |user|
      MigrationEmail.notification_email(user).deliver
    end

  end
end
