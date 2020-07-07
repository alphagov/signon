class UpdateApiUserInUsers < ActiveRecord::Migration[6.0]
  def up
    User.joins(:authorisations)
        .where("oauth_access_tokens.expires_in > ?", 5.years.to_i)
        .group(:id, :email)
        .update_all(api_user: true)
  end

  def down
    User.update_all(api_user: false)
  end
end
