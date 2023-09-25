class StripWhitespaceFromUserName < ActiveRecord::Migration[7.0]
  def change
    User.where("name REGEXP ? OR name REGEXP ?", "^\\s+", "\\s+$").each do |u|
      u.update_attribute(:name, u.name&.strip) # rubocop:disable Rails/SkipsModelValidations
    end
  end
end
