class AddForeignKeyConstraintToApplicationIdOnOauthAccessTokens < ActiveRecord::Migration[7.0]
  def change
    add_foreign_key :oauth_access_tokens, :oauth_applications, column: :application_id
  end
end
