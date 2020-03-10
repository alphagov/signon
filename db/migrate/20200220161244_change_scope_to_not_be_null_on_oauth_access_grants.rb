class ChangeScopeToNotBeNullOnOauthAccessGrants < ActiveRecord::Migration[5.2]
  def up
    change_column_default :oauth_access_grants, :scopes, from: nil, to: ""
    change_column_null :oauth_access_grants, :scopes, false
  end

  def down
    change_column_default :oauth_access_grants, :scopes, from: "", to: nil
    change_column_null :oauth_access_grants, :scopes, true
  end
end
