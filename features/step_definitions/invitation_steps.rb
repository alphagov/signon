ActionMailer::Base.delivery_method = :test
ActionMailer::Base.perform_deliveries = true
ActionMailer::Base.deliveries.clear
  
Given /an invited user/ do
  @user = User.invite!(name: "Jim", email: "jim@web.com")
end

When /I create a user called "(.*)" with email "(.*)"/ do |name, email|
  visit new_user_invitation_path
  fill_in "Name", with: name
  fill_in "Email", with: email
  click_button "Create user and send email"
end

When /I create an admin called "(.*)" with email "(.*)"/ do |name, email|
  visit new_user_invitation_path
  fill_in "Name", with: name
  fill_in "Email", with: email
  select "Admin", from: "Role"
  click_button "Create user and send email"
end

When /the invitation email link is clicked/ do
  visit accept_user_invitation_path(invitation_token: @user.invitation_token)
end

When /I fill in my new passphrase/ do
  fill_in "Passphrase", with: "this 1s 4 v3333ry s3cur3 p4ssw0rd.!Z"
  fill_in "Confirm passphrase", with: "this 1s 4 v3333ry s3cur3 p4ssw0rd.!Z"
  click_button "Set my passphrase"
end

When /^I upload "(.*?)"$/ do |fixture_filename|
  visit new_admin_batch_invitation_path
  path = File.join(::Rails.root, "features", "fixtures", fixture_filename)
  attach_file("Choose a CSV file of users with names and email addresses", path)
  click_button "Create users and send emails"
end

Then /a user should be created with the email "(.*)"/ do |email|
  @user = User.find_by_email(email)
  assert_not_nil @user
end

Then /an invitation email should be sent to "(.*)"/ do |address|
  email = ActionMailer::Base.deliveries.last
  assert_equal address, email.to[0]
  assert_match 'Please confirm your account', email.subject
end
