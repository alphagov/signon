# If you would like to use the SSO syncing functionality
# to push updated permissions and suspensions to apps,
# create a user in Signon and add their email address here.
#
# Signon will make sure the user has the neccessary permissions
# and authorisations to access the applications it needs
# to make requests to.
#

Rails.application.config.to_prepare do
  SSOPushCredential.user_email = ENV["SSO_PUSH_USER_EMAIL"] || "replace.with.user.for.sso.push@digital.cabinet-office.gov.uk"
end
