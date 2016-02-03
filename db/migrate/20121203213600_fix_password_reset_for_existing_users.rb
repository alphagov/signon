class FixPasswordResetForExistingUsers < ActiveRecord::Migration
  def up
    # devise_invitable #invite! calls #skip_confirmation!, which in turn sets confirmed_at to Time.zone.now.
    # That means that when the user accepts the invitation, they are already "confirmed", and everything works.
    #
    # However, because we didn't have confirmable enabled (nor the columns on the user table), that had no effect.
    # Now that we've added confirmable (and the columns on the user table), the behaviour of things like
    # password resets for those existing users breaks because Devise assumes confirmed_at (or confirmation_sent_at)
    # is set.
    #
    # So to make the old users look like users created now, those users need to have confirmed_at set.
    User.where(confirmed_at: nil).update_all("confirmed_at = created_at")
  end
end
