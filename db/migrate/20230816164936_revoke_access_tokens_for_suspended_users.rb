class RevokeAccessTokensForSuspendedUsers < ActiveRecord::Migration[7.0]
  def up
    User.with_status(User::USER_STATUS_SUSPENDED)
      .find_each(&:revoke_all_authorisations)
  end

  def down; end
end
