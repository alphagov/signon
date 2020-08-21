# Troubleshooting

This is a place to record workarounds to some common problems.

## User didn't receive password reset email

All the emails do is send users a link to reset their password. We can find this link and give it to them directly.

First, open a Rails console (Signon is on the backend box in Carrenza).

If you run:

```ruby
token = User.find_by(email: "name@example.com").send_reset_password_instructions
```

you’ll get the token back and can add it into the URL to give to the user:

https://signon.publishing.service.gov.uk/users/password/edit?reset_password_token=<token>
