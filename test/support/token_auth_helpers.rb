module TokenAuthHelpers
  def get_valid_token
    User.last.authorisations.first
  end

  def get_expired_token
    token = get_valid_token
    token.update_column(:created_at, 3.days.ago)
    token.update_column(:expires_in, 30)
    token
  end

  def get_revoked_token
    get_valid_token.tap(&:revoke)
  end
end
