# Suspend all users in an organisation

You might need to suspend all users in an organisation, and later unsuspend
them. You can do this by invoking rake tasks:

* `suspend_organisation_users`
* `unsuspend_organisation_users`

You must provide:

* The organisation slug, such as `department-for-education`
* A reason for the bulk suspension, such as `'Incident on 2001-02-03'`.

The reason will be recorded against each user. Note down the reason so that you
can later provide it to the rake task `unsuspend_organisation_users` to
unsuspend only those users. Otherwise it will be difficult to avoid unsuspending
a user who should remain suspended.

## Example

### Suspend

Suspend all users of the Department of Hats.

```sh
bundle exec rake "suspend_organisation_users['deparment-for-education', 'Incident on 2001-02-03']"
```

This will suspend all users who belong to that organisation and who are not
already suspended.

### Unsuspend

Unsuspend the users later by providing the same organisation slug and reason.

```sh
bundle exec rake "unsuspend_organisation_users['deparment-for-education', 'Incident on 2001-02-03']"
```

This will unsuspend all users who belong to that organisation who were suspended
for the given reason. Passwords will also be reset.
