# Usage Documentation

## Setup Rake Tasks

To create a new client application to which Signon will provide sign-on services:

```sh
rake applications:create name=ClientName description="What does this app do" \
home_uri="https://myapp.com" redirect_uri="https://myapp.com/auth/gds/callback"
```

This will create and return a client ID and secret that can be used in the app
(normally via [GDS-SSO](http://github.com/alphagov/gds-sso)).

You can then add the ID and secret to the app's `ENV` using your preferred
method.

## Access Tokens

You may also need to create an access token, so one application can identify
itself to another. Say, for instance, you have an API that requires
authentication and you need to configure a frontend to make requests of it.
Assuming you have your application set up in Signon under the name
"Stuff API", follow these steps to create an access token for API clients
to access your it:

* Login to Signon with 'superadmin' role
* Click 'API Users', followed by 'Create API User'
* Fill-in a name and email for the API client
* Once saved, click "Add application token", select "Stuff API" and press
  "Create access token"
* You should see an access token on the screen. This is the only time it'll be displayed on screen, so make a note of it if you need to.

Once you've created your access token, you'll probably need to:

1. [Synchronise the token with Kubernetes secrets](https://docs.publishing.service.gov.uk/manual/alerts/signon-api-user-token-expires-soon.html#2-update-the-token-in-the-secrets-used-by-the-consuming-application)
2. Expose the token as an environment variable in govuk-helm-charts ([example](https://github.com/alphagov/govuk-helm-charts/pull/2742))

## Development.

More detail is contained in the
[GDS-SSO Repo](https://github.com/alphagov/gds-sso#use-in-development-mode), but
if you just want to get this working, follow the steps below:

* If you haven't already set real tokens in your app's `ENV`, you'll first need
  to run the following command to make sure your database has got
  OAuth config that matches what the apps use in development mode:

  ```
  bundle exec ./script/make_oauth_work_in_dev
  ```
* You must then make sure you set an environment variable when you run your
  app. eg:

  ```
  GDS_SSO_STRATEGY=real bundle exec rails s
  ```

## Creating, editing and deleting permissions

To manage permissions for an existing app, you first need to have the "superadmin"
role on your account (or have access to someone who does): you'll then be able to
access the "Administer applications" menu item. Under the application you want to
change, follow the "Supported Permissions" link and add, update or delete the
permission from there.

## Creating new organisations

Instead of creating organisations directly in signon we pull them in from
whitehall which is the canonical source.  If you run:

    rake organisations:fetch

This will communicate with whitehall to get the complete list of orgs and
the relationships between them.  It then uses this information to make sure
signon is up to date.

One downside to this is that whitehall allows an org to have multiple parents
whereas signon only allows for a single parent.  Signon's behaviour is
currently to set the parent of an org with multiple parents to the one that
appears last in the api response.

On deployed environments this rake task is run nightly at 11pm via jenkins.
This is configured in [govuk-puppet](https://github.com/alphagov/govuk-puppet).
If you want orgs and their relationships to be modelled correctly in signon,
you should do it whitehall and then let this nightly import do its thing.

## Implementation Notes

The application is divided into two parts: user management (User sign-on and
passwords) and OAuth delegation (SSO service, contacts API).

User management is handled by
[Devise](https://github.com/plataformatec/devise). Configuration is in
`config/initializers/devise` and views are either concrete (under
app/views/devise) or pulled in from the Devise gem. Likewise with Controllers,
though Devise controllers should inherit from `Devise::SomeController` (e.g., as
with the `PasswordsController`).

API authentication is handled by Doorkeeper. It's a bit of a tricky beast, but
not too bad overall, and it nicely separates concerns. Instead of exposing the
current user with `current_user`, Doorkeeper exposes the current valid OAuth
token as `doorkeeper_token`. Doorkeeper tokens are associated with a *resource
owner* through an authenticator block, defined in
`config/initializers/doorkeeper`.

To require Devise authentication in a controller (ie, you want a user sitting at
a computer looking at the page), add `before_action:authenticate_user!` to the
controller.

For example:

```ruby
class SettingsController
  before_action :authenticate_user!

  def show
    settings = current_user.settings
  end
end
```

To require Doorkeeper authentication in a controller (i.e., you want an
application that has been granted a token on behalf of a user to interact with
the controller), add `before_action :doorkeeper_authorize!` to the controller.

For example:

```ruby
class AutomaticApiController
  before_action :doorkeeper_authorize!

  def swizzle
    @token_owning_user = User.find_by_id(doorkeeper_token.resource_owner_id)
  end
end
```
