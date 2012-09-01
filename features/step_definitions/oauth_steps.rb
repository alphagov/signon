Given /^an OAuth application called "([^"]*)"$/ do |application_name|
  FactoryGirl.create(:application, name: application_name)
end

Given /^an OAuth application called "([^"]*)" with SupportedPermission of "([^"]*)"$/ do |application_name, permission_name|
  app = FactoryGirl.create(:application, name: application_name)
  FactoryGirl.create(:supported_permission, application: app, name: permission_name)
end

Given /^the user is authorized for "(.*?)" with permission to "(.*?)"$/ do |application_name, permission_name|
  app = Doorkeeper::Application.find_by_name(application_name)
  permission = app.supported_permissions.find_by_name!(permission_name)
  @user.permissions.create!(application: app, permissions: [permission.name])
  @user.authorisations.create!(application: app)
end

When /^I visit the OAuth authorisation request endpoint for "([^"]*)"$/ do |application_name|
  app = Doorkeeper::Application.find_by_name(application_name)
  visit "/oauth/authorize?response_type=code&client_id=#{app.uid}&redirect_uri=#{app.redirect_uri}"
end

When /^I authorise the app$/ do
  begin
    click_button 'Authorize'
  rescue ActionController::RoutingError, SocketError
    # we don't care about following the non-existent redirect, but we needed to submit the form (which automatically redirects).
  end
end

When /^I decline to authorise the app$/ do
  begin
    click_button 'Deny'
  rescue ActionController::RoutingError, SocketError
    # we don't care about following the non-existent redirect, but we need to submit the form (which automatically redirects).
  end
end

Then /^there should be an authorisation code for the user$/ do
  assert_kind_of Doorkeeper::AccessGrant, Doorkeeper::AccessGrant.find_by_resource_owner_id(@user.id)
end

Then /^there should not be an authorisation code for the user$/ do
  assert_nil Doorkeeper::AccessGrant.find_by_resource_owner_id(@user.id)
end

