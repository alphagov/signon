# coding: utf-8

class ReplaceApostropheInUserEmails < ActiveRecord::Migration[4.2]
  def up
    User.where("email LIKE '%’%'").update_all(email: %q{REPLACE(email, "’", "'") })
  end

  def down
  end
end
