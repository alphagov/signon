class AddUnconfirmedEmail < ActiveRecord::Migration
  def up
    change_table(:users) do |t|
      t.string   :confirmation_token
      t.datetime :confirmed_at
      t.datetime :confirmation_sent_at
      t.string   :unconfirmed_email # Only if using reconfirmable
    end

    # Need to make sure that confirmable treats users who already have access
    # as being "confirmed"
    User.where("invitation_accepted_at is NOT NULL").each do |user|
      user.update_column(:confirmed_at, user.invitation_accepted_at)
    end
    # Covers users who were created before devise_invitable
    User.where("invitation_accepted_at is NULL and sign_in_count > 0").each do |user|
      user.update_column(:confirmed_at, user.created_at)
    end
  end

  def down
    change_table(:users) do |t|
      t.string   :confirmation_token
      t.datetime :confirmed_at
      t.datetime :confirmation_sent_at
      t.string   :unconfirmed_email # Only if using reconfirmable
    end
  end
end
