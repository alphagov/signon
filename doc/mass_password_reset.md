You might need to email all Signon users to reset their passwords. You
could use a class like this to do it:

```ruby
class PasswordResetEmail < ActionMailer::Base
  def notification_email(user)
    to = user.email
    mail(to: to,
    from: 'GOV.UK Signon <incident-response@govuk.zendesk.com>',
    reply_to: 'incident-response@govuk.zendesk.com',
    subject: 'Your GOV.UK Signon password will be reset',
    content_type: 'text/plain',
    body: %Q{Hi,

Your Signon password will be reset at TIME on DAY MONTH. You’ll be
able to work on GOV.UK as normal until that time. You don’t need to
take any action now.

This is happening to all Signon accounts and is part of ongoing work
to make GOV.UK more secure.
On DAY MONTH, you’ll be logged out of Signon. You’ll then get an email
telling you how to get a new password.

Once you have a new password you'll be able to continue to work on
GOV.UK as normal.

INSERT YOUR SIGNATURE HERE
})
  end
end
```

The above copy has been written by content team and signed off for the use of a mass password
reset. You should use it and replace the date, time and signature when you come to use it.

You should test this on yourself:

```ruby
User.where(email: 'user.name@digital.cabinet-office.gov.uk').each do |user|
  begin
    puts "Attempting to email: #{user.email}"
    PasswordResetEmail.notification_email(user).deliver
  rescue Exception => err
    puts "FAILED trying to email: #{user.email}. Error: #{err}"
  end
end
```

And send it to all users who have signed in recently:

```ruby
User.last_signed_in_after(90.days.ago).each do |user|
  begin
    puts "Attempting to email: #{user.email}"
    PasswordResetEmail.notification_email(user).deliver
  rescue Exception => err
    puts "FAILED trying to email: #{user.email}. Error: #{err}"
  end
end
```

When you need to reset their passwords:

```ruby
random_password = User.send(:generate_token, 'encrypted_password').slice(0, 20)
user.password = random_password
user.password_confirmation = random_password
if user.save
  ReauthEnforcer.perform_on(user)
  user.send_reset_password_instructions
else
  puts user.errors.full_messages
end
```
