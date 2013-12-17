Given /^an OAuth application called "([^"]*)"$/ do |application_name|
  create(:application, name: application_name)
end

Given /^an OAuth application called "([^"]*)" with SupportedPermission of "([^"]*)"$/ do |application_name, permission_name|
  app = create(:application, name: application_name)
  create(:supported_permission, application_id: app.id, name: permission_name)
end

Given /^the user is authorized for "(.*?)" with permission to "(.*?)"$/ do |application_name, permission_name|
  app = Doorkeeper::Application.find_by_name(application_name)
  permission = app.supported_permissions.find_by_name!(permission_name)
  @user.permissions.create!(application_id: app.id, permissions: [permission.name])
  @user.authorisations.create!(application_id: app.id)
end

When /^I sign in, ignoring routing errors$/ do
  begin
    step "I sign in"
  rescue ActionController::RoutingError, SocketError
  end
end

When /^I visit the OAuth authorisation request endpoint for "([^"]*)"$/ do |application_name|
  begin
    app = Doorkeeper::Application.find_by_name(application_name)
    visit "/oauth/authorize?response_type=code&client_id=#{app.uid}&redirect_uri=#{app.redirect_uri}"
  rescue ActionController::RoutingError, SocketError
  end
end

Then /^there should be an authorisation code for the user$/ do
  assert_kind_of Doorkeeper::AccessGrant, Doorkeeper::AccessGrant.find_by_resource_owner_id(@user.id)
end
