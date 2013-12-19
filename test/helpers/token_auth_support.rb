module TokenAuthSupport
  def get_valid_token
    token = User.last.authorisations.first
  end

  def get_expired_token
    token = get_valid_token
    token.update_column(:created_at, 3.days.ago)
    token.update_column(:expires_in, 30)
    token
  end

  def get_revoked_token
    token = get_valid_token
    token.revoke
    token
  end

  def set_bearer_token(token)
    options = page.driver.instance_variable_get("@options")
    options[:headers] = { "HTTP_AUTHORIZATION" => "Bearer #{token}" }
    page.driver.instance_variable_set "@options", options
  end
end
