Given /^SES will raise a blacklist error$/ do
  Devise::Mailer.any_instance.expects(:mail).with(anything)
      .raises(AWS::SES::ResponseError, OpenStruct.new(error: { 'Code' => "MessageRejected", 'Message' => "Address blacklisted." }))
end

When /^I request a new passphrase for "([^"]*)"$/ do |email|
  visit new_user_password_path
  fill_in "Email", with: email
  click_button "Send me passphrase reset instructions"
end

When /^I complete the passphrase reset form setting my passphrase to "(.*?)"$/ do |new_phrase|
  @user.reload
  visit edit_user_password_path(reset_password_token: @user.reset_password_token)
  fill_in "New passphrase", with: new_phrase
  fill_in "Confirm new passphrase", with: new_phrase
  click_button "Change my passphrase"
end

Then /^my passphrase should (?:still )?be "(.*?)"$/ do |passphrase|
  @user.reload
  @user.valid_password?(passphrase)
end
