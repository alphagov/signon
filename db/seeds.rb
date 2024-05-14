return if Rails.env.test?

gds = Organisation.create!(
  name: "Government Digital Service",
  content_id: Organisation::GDS_ORG_CONTENT_ID,
  organisation_type: :ministerial_department,
  slug: "government-digital-service",
)

User.create!(
  name: "Test Superadmin",
  email: "test.superadmin@gov.uk",
  password: "6fe552ca-d406-4c54-b7a6-041ed1ade6cd",
  role: Roles::Superadmin.name,
  confirmed_at: Time.current,
  organisation: gds,
)

User.create!(
  name: "Test Admin",
  email: "test.admin@gov.uk",
  password: "6fe552ca-d406-4c54-b7a6-041ed1ade6cd",
  role: Roles::Admin.name,
  confirmed_at: Time.current,
  organisation: gds,
)

User.create!(
  name: "Test Super Organisation Admin",
  email: "test.super-organisation-admin@gov.uk",
  password: "6fe552ca-d406-4c54-b7a6-041ed1ade6cd",
  role: Roles::SuperOrganisationAdmin.name,
  confirmed_at: Time.current,
  organisation: gds,
)

User.create!(
  name: "Test Organisation Admin",
  email: "test.organisation-admin@gov.uk",
  password: "6fe552ca-d406-4c54-b7a6-041ed1ade6cd",
  role: Roles::OrganisationAdmin.name,
  confirmed_at: Time.current,
  organisation: gds,
)

test_organisation_without_2sv = Organisation.create!(
  name: "Test Organisation without mandatory 2SV",
  content_id: SecureRandom.uuid,
  organisation_type: :ministerial_department,
  slug: "test-organisation",
  require_2sv: false,
)

test_organisation_with_2sv = Organisation.create!(
  name: "Test Organisation with mandatory 2SV",
  content_id: SecureRandom.uuid,
  organisation_type: :ministerial_department,
  slug: "test-organisation-with-2sv",
  require_2sv: true,
)

User.create!(
  name: "Test User",
  email: "test.user@gov.uk",
  password: "6fe552ca-d406-4c54-b7a6-041ed1ade6cd",
  role: Roles::Normal.name,
  confirmed_at: Time.current,
  organisation: test_organisation_without_2sv,
)

# The following user has 2SV enabled by default. Scan the QR code with your authenticator app to generate a code to login.
# █████████████████████████████████████████████████
# █████████████████████████████████████████████████
# ████ ▄▄▄▄▄ ██▀█▄▄▄▄██▄ █▀ ██▀▄▀█▀█▄█▀█ ▄▄▄▄▄ ████
# ████ █   █ █▀ ▀▀▀█ █▀█▀▄ ▀  █ ▀▀▄▄ ▄ █ █   █ ████
# ████ █▄▄▄█ █▄▄▀█▄█  ▄ █▀▄▄ ▄▄▀ ▀▀ ████ █▄▄▄█ ████
# ████▄▄▄▄▄▄▄█▄█▄▀ █ ▀ █▄▀ █ ▀▄█▄█▄█ ▀▄█▄▄▄▄▄▄▄████
# ████▄ ▀█▀▄▄ ▀▄██  ▄▀▄ █ ██▄▀ ▄▀▀█▄▀▀█▀█▀ ▄▀▀▀████
# ████ ▄██ ▀▄ ▀▄ ▀▀ ▄ ▄ ▀██▀ █▄ ▀  ▄▄█▄▀▄ █▀█  ████
# ████▄  █▄▀▄ ▄▀██▀▄█▄█▄▀▄██ ▄▀▀  █▀▄▀ ▀▀█▀▄▀  ████
# ████▀█ ██▄▄▄▀█ █▀█ ▄ ▄▀█ ██▀▀▄ ▀█▄█ ▀█▀   ▀█▀████
# ████▄▀█  █▄▄▄  ▀█▄▀ ▀▄ █▀▀▄ █▄ ▀▀▄▀ ▀█▀█▀██▀▀████
# ████▄▄▄ ▄ ▄██▄▄▀█▄ ▄▀▄▄  █  ▀█▀   ▀ ██ ▀█▀▄ ▄████
# ████ █▄  █▄  ▄▄█▄▀█▄█▀▄██▄█▀▀▄██  ▄█  ▄██ ▄ ▄████
# ████▄▄█▀ ▄▄█ ▀  ▄█ ▀▀▄▀ ▀▄   █ ▄▄▄▀▄█▀ ▀▄▀ ▀▀████
# ██████  ▄▄▄█▄ ▄▀█▀▄▀ ▀█▀▀█▀ ███▀▄▀  ▀▀ ▄▀ ███████
# ████▀▄▀▀▀ ▄ ██▄▀      ▀▀ █▄██ ▄ █▀▄▀▄█ ██ ▀ ▀████
# ████ ▄  ▄▄▄█ ▄▄▄▀█▄▄▄█▀███▀▀▀ ▀ ▄ ▄  ▀█▄▀ ▄█▀████
# ████ ▄▀▀▄▄▄▄▄█▄▄▀▄ ▄█▄█▄▄█▄  █ ▀▄█▀ ██▄▄▄▀▄▀▄████
# ████▄█▄▄▄▄▄█   ▀▀█▀ ▄▄▀▀▄▀▀▀▄▄█ ▄ ▀▄ ▄▄▄ ▀ █ ████
# ████ ▄▄▄▄▄ █ ▀█ ██▀  █▄▀█▀██▄▄ ▄ ▀▄▄ █▄█ ▀██ ████
# ████ █   █ ██▄▀█▄▄ █  ▄▄▄▀  ▀   ██▄▄▄ ▄ ▄▄▀▀ ████
# ████ █▄▄▄█ █▀▀▄ ▄▄█▀█▄▄▄▄█ ▀█▄▀▀▀█▀███ █ █ ▄▀████
# ████▄▄▄▄▄▄▄█▄█▄▄▄▄██▄▄▄█▄████▄▄██▄█▄▄▄███████████
# █████████████████████████████████████████████████
# █████████████████████████████████████████████████

User.create!(
  name: "Test User with 2SV enabled",
  email: "test.user.2sv@gov.uk",
  password: "6fe552ca-d406-4c54-b7a6-041ed1ade6cd",
  role: Roles::Normal.name,
  confirmed_at: Time.current,
  organisation: test_organisation_without_2sv,
  require_2sv: true,
  otp_secret_key: "I5X6Y3VN3CAATYQRBPAZ7KMFLK2RWYJ5",
)

User.create!(
  name: "Test User from organisation with mandatory 2SV",
  email: "test.user.2sv.organisation@gov.uk",
  password: "6fe552ca-d406-4c54-b7a6-041ed1ade6cd",
  role: Roles::Normal.name,
  confirmed_at: Time.current,
  organisation: test_organisation_with_2sv,
  require_2sv: true,
  otp_secret_key: "I5X6Y3VN3CAATYQRBPAZ7KMFLK2RWYJ5",
)

User.create!(
  name: "Test Api User",
  api_user: true,
  email: "test.apiuser@gov.uk",
  password: "6fe552ca-d406-4c54-b7a6-041ed1ade6cd",
  role: Roles::Normal.name,
  confirmed_at: Time.current,
  require_2sv: false,
)

application = Doorkeeper::Application.create!(
  name: "Test Application 1",
  redirect_uri: "https://www.gov.uk",
)

SupportedPermission.create!(
  name: "Editor",
  application:,
)

application_with_9_permissions = Doorkeeper::Application.create!(
  name: "Test Application with 9 Permissions",
  redirect_uri: "https://www.gov.uk",
)

9.times do |index|
  SupportedPermission.create!(
    name: "permission-#{index}",
    application: application_with_9_permissions,
  )
end
