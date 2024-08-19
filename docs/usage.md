# Usage Documentation <!-- this could do with a good clean up and update >

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
to access your it: <!-- access your what? -->

* Login to Signon with 'superadmin' role
* Click 'API Users', followed by 'Create API User'
* Fill-in a name and email for the API client
* Once saved, click "Add application token", select "Stuff API" and press
  "Create access token"
* You should see an access token on the screen, which you must copy as it
  is the only time it'll be displayed on screen.

## Development

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

## Creating new organisations

Instead of creating organisations directly in Signon we pull them in from
Whitehall which is the canonical source. If you run:

```
rake organisations:fetch
```

This will communicate with Whitehall to get the complete list of organisations
and the relationships between them. It then uses this information to make sure
Signon is up to date.

One downside to this is that Whitehall allows an organisation to have multiple
parents whereas Signon only allows for a single parent. Signon's behaviour is
currently to set the parent of an organisation with multiple parents to the one
that appears last in the api response.

On deployed environments this rake task is run nightly at 11pm via jenkins.
This is configured in [govuk-puppet](https://github.com/alphagov/govuk-puppet). <!-- I don't think we use Puppet (or Jenkins?) anymore >
If you want organisations and their relationships to be modelled correctly in
Signon, you should do it in Whitehall and then let this nightly import do its
thing.

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
