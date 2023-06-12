# Create a user in Signon with the following email address:
#
#   signon+permissions@alphagov.co.uk
#
# Signon will use this user for the SSO syncing functionality
# to push updated permissions and suspensions to apps.
#
# Signon will make sure the user has the neccessary permissions
# and authorisations to access the applications it needs
# to make requests to.
#

Rails.application.config.to_prepare do
end
