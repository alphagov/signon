When /^I change their email to "(.*?)"$/ do |new_email|
  visit edit_admin_user_path(@user)
  fill_in "Email", with: new_email
  click_button "Update User"
end

Then /^a confirmation email should be sent to "(.*?)"$/ do |new_email|
  email = ActionMailer::Base.deliveries.last
  assert_equal new_email, email.to[0]
  assert_equal 'Confirm your email change', email.subject
end

Given /^a user with a pending email change$/ do
  @user = FactoryGirl.create(:user, email: "old@email.com", unconfirmed_email: "new@email.com", confirmation_token: "a1s2d3")
end

When /^the confirm email link is clicked$/ do
  visit user_confirmation_path(confirmation_token: @user.confirmation_token)
end

When /^I sign-out$/ do
  visit destroy_user_session_path
end

When /^I cancel the email change$/ do
  visit edit_admin_user_path(@user)
  click_link "Cancel email change"
end