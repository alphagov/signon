class UpdateSSOPushUserName < ActiveRecord::Migration[7.0]
  OLD_USER_NAME = "Signonotron API Client (permission and suspension updater)".freeze
  NEW_USER_NAME = "Signon API Client (permission and suspension updater)".freeze
  USER_EMAIL = "signon+permissions@alphagov.co.uk".freeze

  def up
    update "UPDATE users SET name = '#{NEW_USER_NAME}' WHERE email = '#{USER_EMAIL}'"
  end

  def down
    update "UPDATE users SET name = '#{OLD_USER_NAME}' WHERE email = '#{USER_EMAIL}'"
  end
end
