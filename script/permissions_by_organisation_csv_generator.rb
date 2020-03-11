require "csv"

class PermissionsByOrganisationCsvGenerator
  def self.generate
    filename = "permissions_by_organisation.csv"
    CSV.open(filename, "wb") do |csv|
      csv << %w[Organisation Application Permission]
      permissions_by_organisation.each { |line| csv << line }
    end
    puts "Permissions by organisations saved to ./#{filename}"
  end

  def self.permissions_by_organisation
    permissions_by_organisation = []
    Organisation.includes(users: { permissions: :application }).each do |organisation|
      organisation.users.each do |user|
        user.permissions.each do |permission|
          permission.permissions.each do |permission_name|
            permissions_by_organisation << [organisation.name, permission.application.name, permission_name]
          end
        end
      end
    end
    permissions_by_organisation.uniq
  end
end

PermissionsByOrganisationCsvGenerator.generate
