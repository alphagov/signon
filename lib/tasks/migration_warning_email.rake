namespace :recent_users do
  desc "Email recent users regarding upcoming migration to Platform 1"
  task :migration_email => :environment do

    class MigrationEmail < ActionMailer::Base
      def notification_email(user)
        to = user.email
        mail(to: to,
             from: "test@alphagov.co.uk",
             reply_to: "test@alphagov.co.uk",
             subject: "Migration on 25 March 2014",
             content_type: "text/html",
             body: "There will be downtime on 25 March 2014 from 18:00 until 23:00 due to a platform change.\nPlease avoid publishing content at that time.",
            )
      end
    end

    User.last_signed_in_at(90.days.ago).each do |user|
      MigrationEmail.notification_email(user).deliver
    end

  end
end
