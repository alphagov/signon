class AddNotNullConstraintToOauthApplicationsRetired < ActiveRecord::Migration[7.0]
  def change
    change_column_null :oauth_applications, :retired, false, false
  end
end
