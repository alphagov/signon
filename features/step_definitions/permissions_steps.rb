Given /^another user$/ do
  @another_user = FactoryGirl.create(:user)
end

When /^I add "([^"]*)" permission to "([^"]*)"$/ do |permission, application|
  visit "/admin/users/#{@another_user.to_param}/edit"
  select permission, :from => "Permissions for #{application}" #'user[permissions_attributes][1][permissions][]'
  click_button "Update User"
end

Then /^a permission should be created for "([^"]*)" with permissions of "([^"]*)"$/ do |application_name, permission_string|
  application = ::Doorkeeper::Application.find_by_name(application_name)
  permission = Permission.where(application_id: application.id, user_id: @another_user.id).first
  assert_equal [permission_string], permission.permissions
end