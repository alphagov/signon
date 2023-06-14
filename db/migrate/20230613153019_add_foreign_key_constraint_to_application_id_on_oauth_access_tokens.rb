class AddForeignKeyConstraintToApplicationIdOnOauthAccessTokens < ActiveRecord::Migration[7.0]
  def change
    Doorkeeper::AccessToken.all.select { |at| at.application.nil? }.each do |access_token|
      Doorkeeper::Application.create!(
        id: access_token.application_id,
        name: "Unknown #{access_token.application_id}",
        redirect_uri: "https://example.com/",
        description: "Added in migration (previously deleted?)",
      )
    end

    add_foreign_key :oauth_access_tokens, :oauth_applications, column: :application_id
  end
end
