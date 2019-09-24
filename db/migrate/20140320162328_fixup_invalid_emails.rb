class FixupInvalidEmails < ActiveRecord::Migration
  class TempUser < ActiveRecord::Base
    self.table_name = "users"
  end

  def up
    TempUser.find_each do |user|
      # There are entries in the db with various invalid chars on the end.
      # These range from commas to odd unicode whitespace chars (eg U200E)
      # The last char of any valid email address should be an ascii letter.
      cleaned = user.email.sub(/[^a-z]+\z/i, "")
      if user.email != cleaned
        puts "Fixing email address for '#{user.email}'"
        user.email = cleaned
        user.save!
      end
    end
  end

  def down; end
end
