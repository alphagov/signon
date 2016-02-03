class FixPasswordResetForSomeUsers < ActiveRecord::Migration
  def up
    # For us, a user is "confirmed" when they're created, even though this is
    # conceptually confusing.
    #
    # If you've been invited but not yet accepted, and confirmed_at isn't set,
    # passsword reset won't work, even though it should.
    #
    # There was a change in behaviour of devise_invitable which meant that confirmed_at
    # was no longer set at create/invite time.
    # We've reinstated that, but we need to fix accounts created in the meantime.
    User.where(confirmed_at: nil).update_all("confirmed_at = created_at")
  end
end
