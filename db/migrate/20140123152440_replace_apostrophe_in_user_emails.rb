# coding: utf-8

class ReplaceApostropheInUserEmails < ActiveRecord::Migration
  def up
    User.where(%q{ email LIKE "%’%" }).update_all(%q{ email = REPLACE(email, "’", "'") })
  end

  def down
  end
end
