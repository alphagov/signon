# Troubleshooting

This is a place to record workarounds to some common problems.

## User didn't receive password reset email

Signon currently uses Amazon Simple Email Service (SES) to send emails to users. Amazon SES emails don’t pass strict [DMARC](https://dmarc.org/) setups. This means that some mail servers block Signon emails because they can't tell them apart from phishing or spoof emails.

The proper fix to this is to move Signon to use GOV.UK Notify, but until that happens we need to find a way to allow users to reset the passwords.

### Finding the reset password link

All the emails do is send users a link to reset their password. We can find this link and give it to them directly.

First, open a Rails console (Signon is on the backend box in Carrenza).

If you run:

```ruby
token = User.find_by(email: "name@example.com").send_reset_password_instructions
```

you’ll get the token back and can add it into the URL to give to the user:

https://signon.publishing.service.gov.uk/users/password/edit?reset_password_token=<token>
