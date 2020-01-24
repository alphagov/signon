require "csv"

module DataHygiene
  class BulkOrganisationUpdater
    def initialize(filename)
      @filename = filename
    end

    def call
      CSV.foreach(filename, **CSV_OPTIONS) do |row|
        process_row(row)
      end
    end

    def self.call(*args)
      new(*args).call
    end

  private

    attr_reader :filename

    CSV_OPTIONS = {
      headers: true,
    }.freeze

    def process_row(row)
      user = find_user(row)
      new_email_address = find_new_email_address(row)
      new_organisation = find_new_organisation(row)

      update_user(user, new_email_address, new_organisation)
    end

    def find_user(row)
      User.find_by!(email: row.fetch("Old email"))
    end

    def find_new_email_address(row)
      row.fetch("New email")
    end

    def find_new_organisation(row)
      Organisation.find_by!(slug: row.fetch("New organisation"))
    end

    def update_user(user, new_email_address, new_organisation)
      puts "#{user.email}: #{new_email_address} #{new_organisation.slug}"

      current_email_address = user.email

      user.skip_confirmation_notification!

      user.update!(
        email: new_email_address,
        organisation: new_organisation,
      )

      user.confirm # we trust the email addresses in the CSV spreadsheet

      EventLog.record_email_change(user, current_email_address, new_email_address)
    end
  end
end
