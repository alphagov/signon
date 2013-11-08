# Generates a hash suitable for exposing to an application integrating with
# signon for SSO over OAuth. Also used when pushing user updates, which isn't
# part of OAuth.
class UserOAuthPresenter < Struct.new(:user, :application)
  def as_hash
    {
      user: {
        uid: user.uid,
        name: user.name,
        email: user.email,
        permissions: permissions_strings,
        organisation_slug: organisation_slug,
      }
    }
  end

  def permissions_strings
    permission = user.permissions.where(application_id: application.id).first
    permission.nil? ? [] : permission.permissions
  end

  def organisation_slug
    organisation = user.organisation
    organisation.nil? ? nil : organisation.slug
  end
end
