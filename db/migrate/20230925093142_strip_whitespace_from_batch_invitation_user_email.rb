class StripWhitespaceFromBatchInvitationUserEmail < ActiveRecord::Migration[7.0]
  def change
    BatchInvitationUser.where("email REGEXP ? OR email REGEXP ?", "^\\s+", "\\s+$").each do |biu|
      biu.update_attribute(:email, biu.email&.strip) # rubocop:disable Rails/SkipsModelValidations
    end
  end
end
