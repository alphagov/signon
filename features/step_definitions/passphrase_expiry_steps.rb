Given /^I am a user with email "(.*?)" and passphrase "(.*?)"$/ do |email, passphrase|
  # This is an alias for another step, but reads better
  step %{a user exists with email "#{email}" and passphrase "#{passphrase}"}
end

Given /^I last changed my passphrase (\d+) days ago$/ do |number_of_days|
  @user.update_column :password_changed_at, number_of_days.to_i.days.ago
end

Given /^I am being prompted for a new passphrase$/ do
  email      = "email@example.com"
  passphrase = "some v3ry s3cure passphrase"

  step %{a user exists with email "#{email}" and passphrase "#{passphrase}"}
  @user.update_column :password_changed_at, 90.days.ago
  step %{I sign in}
end

When /^I make a mistake entering my existing passphrase$/ do
  new_passphrase = "some 3v3n more s3cure passphrase"
  reset_expired_passphrase("nonsense", new_passphrase, new_passphrase)
end

Then /^I should continue to be prompted for a new passphrase$/ do
  assert page.has_content?("Choose a new passphrase"), page.body
end

When /^I go to the dashboard$/ do
  visit root_path
end

When /^I fill in the form with existing passphrase "(.*?)" and new passphrase "(.*?)"$/ do |old_passphrase, new_passphrase|
  reset_expired_passphrase(old_passphrase, new_passphrase, new_passphrase)
end

Then /^I should be on the dashboard$/ do
  assert_equal root_url, current_url
end
