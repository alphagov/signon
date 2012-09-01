require 'factory_girl'

Given /^a user exists with email "([^"]*)" and passphrase "([^"]*)"$/ do |email, passphrase|
  @user = User.create!(email: email, password: passphrase, password_confirmation: passphrase, name: email.split('@').first)
end

Given /^a signed\-in user exists with email "([^"]*)" and passphrase "([^"]*)"$/ do |email, passphrase|
  step "a user exists with email \"#{email}\" and passphrase \"#{passphrase}\""
  step "I try to sign in with email \"#{email}\" and passphrase \"#{passphrase}\""
end

Given /^a signed\-out user$/ do
  @user = FactoryGirl.create(:user)
end

Given /^a signed\-out admin user$/ do
  @user = FactoryGirl.create(:user, is_admin: true)
end

When /^I sign in$/ do
  step "I try to sign in with email \"#{@user.email}\" and passphrase \"#{@user.password}\""
end

Given /^a signed\-in user$/ do
  step 'a signed-out user'
  step 'I sign in'
end

Given /^a signed\-in admin user$/ do
  step 'a signed-out admin user'
  step 'I sign in'
end

Given /^"(.*?)" is a suspended account because of "(.*?)"$/ do |email, reason|
  User.find_by_email(email).suspend!(reason)
end

When /^I try to sign in with email "([^"]*)" and passphrase "([^"]*)"$/ do |email, passphrase|
  visit new_user_session_path
  fill_in "Email", with: email
  fill_in "Passphrase", with: passphrase
  click_button "Sign in"
end

When /^I try to sign in (\d+) times with email "([^"]*)" and passphrase "([^"]*)"$/ do |repeat, email, passphrase|
  repeat.to_i.times do
    step "I try to sign in with email \"#{email}\" and passphrase \"#{passphrase}\""
  end
end

Then /^I should see "([^"]*)"$/ do |content|
  assert page.has_content?(content)
end

Given /^no user exists with email "([^"]*)"$/ do |email|
  assert ! User.find_by_email(email)
end

Then /^I should not see "([^"]*)"$/ do |content|
  assert ! page.has_content?(content)
end
