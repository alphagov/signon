Given /^they have been locked out$/ do
  User.last.lock_access!
end

When /^I go to the list of users$/ do
  visit admin_users_path
end

Then /^I should see a button to unlock account$/ do
  assert page.find_button('Unlock'), "Can't find unlock button"
end

When /^I press the unlock button$/ do
  click_button 'Unlock'
end

Then /^"([^"]*)" should be unlocked$/ do |email|
  assert ! User.find_by_email(email).access_locked?
end