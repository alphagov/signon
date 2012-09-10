When /^I request user details with a valid bearer token$/ do
  set_bearer_token(get_valid_token.token)
  visit "/user.json"
end

When /^I request user details with an invalid bearer token$/ do
  set_bearer_token(get_valid_token.token.reverse)
  visit "/user.json"
end

When /^I request user details with an expired bearer token$/ do
  set_bearer_token(get_expired_token.token)
  visit "/user.json"
end

When /^I request user details with a revoked bearer token$/ do
  token = get_valid_token
  set_bearer_token(token.token)
  token.revoke
  visit "/user.json"
end

When /^I request user details without a bearer token$/ do
  visit "/user.json"
end

Then /^I should receive a successful JSON response$/ do
  @parsed_response = JSON.parse(page.source)
  assert @parsed_response.has_key?('user')
end

Then /^the response should indicate it needs authorization$/ do
  assert_equal 401, page.status_code
end

Then /^I should get a list of the user's permissions for "(.*?)"$/ do |arg1|
  assert @parsed_response['user']['permissions']['MyApp'].is_a?(Array)
end