Given /^a user exists with email "([^"]*)" and passphrase "([^"]*)"$/ do |email, passphrase|
  User.create!(email: email, password: passphrase, password_confirmation: passphrase)
end

Given /^"([^"]*)" is a suspended account$/ do |email|
  User.find_by_email(email).suspend!
end

When /^I try to sign in with email "([^"]*)" and passphrase "([^"]*)"$/ do |email, passphrase|
  visit new_user_session_path
  fill_in "Email", with: email
  fill_in "Passphrase", with: passphrase
  click_button "Sign in"
end

Then /^show me the page$/ do
  save_and_open_page
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

When /^I request a new passphrase for "([^"]*)"$/ do |email|
  visit new_user_password_path
  fill_in "Email", with: email
  click_button "Send me passphrase reset instructions"
end

Then /^I should not see "([^"]*)"$/ do |content|
  assert ! page.has_content?(content)
end

When /^I change the passphrase to "([^"]*)" from "([^"]*)"$/ do |new_passphrase, existing_passphrase|
  visit edit_user_password_path
  fill_in "New Password", with: new_passphrase
  fill_in "Existing Password", with: existing_passphrase
  click_button "Change password"
end
