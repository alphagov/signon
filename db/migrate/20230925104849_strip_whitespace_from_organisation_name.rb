class StripWhitespaceFromOrganisationName < ActiveRecord::Migration[7.0]
  def change
    Organisation.where("name REGEXP ? OR name REGEXP ?", "^\\s+", "\\s+$").each do |o|
      o.update_attribute(:name, o.name&.strip) # rubocop:disable Rails/SkipsModelValidations
    end
  end
end
