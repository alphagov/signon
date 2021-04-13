# Troubleshooting

This is a place to record workarounds to some common problems.

## User didn't receive password reset email

When a user account is created, they are sent a link to reset their password. A similar email is sent when users request a password reset email.

In the first instance, a new email should be requested. The route is different depending on the type of password reset email.

### New user account

As a superadmin user, in Signon, find the user and press the 'Resend signup email' button.

### Password reset email

The user can request a new password reset link themselves through the [password reset form](https://signon.publishing.service.gov.uk/users/password/new).

### User does not receive the email

If a user does not receive this email after attempting to reteieve it again themselves, you may wish to send it directly to their email address.

There are two ways of retrieving the link:

#### Notify dashboard

This method is preferred as you do not need to open a Rails console on a production system.

If the email was sent in the last 7 days, it can be retrieved by searching for the user's email address in the [GOV.UK Notify dashboard](https://www.notifications.service.gov.uk/services/51c6b7b7-f7dc-421c-9105-7b73774cfb43).

#### Rails console

First, open a Rails console:

```
gds govuk c app-console -e <environment> signon
```

Run the following to obtain a token:

```ruby
token = User.find_by(email: "name@example.com").send_reset_password_instructions
```

Add it into the URL to give to the user (e.g. for production):

```
https://signon.publishing.service.gov.uk/users/password/edit?reset_password_token=<token>
```
