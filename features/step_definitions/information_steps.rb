When /^I go to the edit page for "(.*?)"$/ do |email|
  visit edit_admin_user_path(User.find_by_email(email))
end

Then /^I should see that they were suspended for "(.*?)"$/ do |reason|
  assert page.has_content?(reason)
end