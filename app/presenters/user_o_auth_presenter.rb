# Generates a hash suitable for exposing to an application integrating with
# signon for SSO over OAuth. Also used when pushing user updates, which isn't
# part of OAuth.
UserOAuthPresenter = Struct.new(:user, :application) do
  def as_hash
    {
      user: {
        uid: user.uid,
        name: user.name,
        email: user.email,
        permissions: permissions,
        organisation_slug: organisation_slug,
        organisation_content_id: organisation_content_id,
        disabled: user.suspended?,
      },
    }
  end

  def permissions
    user.suspended? ? [] : user.permissions_for(application)
  end

  def organisation_slug
    organisation = user.organisation
    organisation.nil? ? nil : organisation.slug
  end

  def organisation_content_id
    organisation = user.organisation
    organisation.nil? ? nil : organisation.content_id
  end
end
