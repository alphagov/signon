class ChangeBatchInvitationUsersToUseUtf8mb3Charset < ActiveRecord::Migration[7.0]
  def up
    execute "ALTER TABLE `batch_invitation_users` DEFAULT CHARACTER SET = utf8mb3;"
    execute "ALTER TABLE `batch_invitation_users` MODIFY COLUMN `name` varchar(255) CHARACTER SET utf8mb3;"
    execute "ALTER TABLE `batch_invitation_users` MODIFY COLUMN `email` varchar(255) CHARACTER SET utf8mb3;"
    execute "ALTER TABLE `batch_invitation_users` MODIFY COLUMN `outcome` varchar(255) CHARACTER SET utf8mb3;"
    execute "ALTER TABLE `batch_invitation_users` MODIFY COLUMN `organisation_slug` varchar(255) CHARACTER SET utf8mb3;"
  end
end
