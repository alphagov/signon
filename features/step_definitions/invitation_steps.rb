ActionMailer::Base.delivery_method = :test
ActionMailer::Base.perform_deliveries = true
ActionMailer::Base.deliveries.clear
  
Given /an invited user/ do
  @user = User.invite!(name: "Jim", email: "jim@web.com")
end

When /I create an admin user called "(.*)" with email "(.*)"/ do |name, email|
  visit new_user_invitation_path
  fill_in "Name", with: name
  fill_in "Email", with: email
  check "Is admin"
  click_button "Create user and send email"
end

When /I am at the invited user set password screen/ do
  visit accept_user_invitation_path(invitation_token: @user.invitation_token)
end

When /I fill in the password/ do
  fill_in "Password", with: "this 1s 4 v3333ry s3cur3 p4ssw0rd.!Z"
  fill_in "Confirm passphrase", with: "this 1s 4 v3333ry s3cur3 p4ssw0rd.!Z"
  click_button "Set my password"
end

Then /an admin user should be created with the email "(.*)"/ do |email|
  @user = User.find_by_email(email)
  assert_not_nil @user
  assert_equal true, @user.is_admin
end

Then /an invitation email should be sent to "(.*)"/ do |address|
  email = ActionMailer::Base.deliveries.last
  assert_equal address, email.to[0]
end
