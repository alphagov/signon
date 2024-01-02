class StripWhitespaceFromBatchInvitationUserName < ActiveRecord::Migration[7.0]
  def change
    BatchInvitationUser.where("name REGEXP ? OR name REGEXP ?", "^\\s+", "\\s+$").find_each do |u|
      u.update_attribute(:name, u.name&.strip) # rubocop:disable Rails/SkipsModelValidations
    end
  end
end
