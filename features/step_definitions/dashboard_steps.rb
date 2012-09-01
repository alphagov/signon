When /^I go to the homepage$/ do
  visit root_path
end

Then /^I should see a link and description for "(.*?)"$/ do |application_name|
  app = Doorkeeper::Application.find_by_name(application_name)
  assert page.has_content?(app.description)
  assert page.has_css?("a[href='#{app.home_uri}']")
end