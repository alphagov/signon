Given /^an OAuth application called "([^"]*)"$/ do |application_name|
  FactoryGirl.create(:application, name: application_name)
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

