# Sign-on-o-Tron II

This is a centralised OAuth 2-based single sign-on provider for GDS services.

We use [Devise](https://github.com/plataformatec/devise) to provide username / password sign-in, and [Doorkeeper](https://github.com/applicake/doorkeeper/) to provide an OAuth 2 provider.


## Usage

The application has two rake tasks to create new users and client applications.

To create a new user, use the following syntax:

`rake users:create name='First Last' email=user@example.com [github=username] [twitter=username]`

To create a new client application to which Sign-on-o-Tron will provide sign-on services:

`rake applications:create name=ClientName description="What does this app do" home_uri="https://myapp.com" redirect_uri="https://myapp.com/redirect"`

which will create and return a client ID and secret that can be used in the app (normally via [GDS-SSO](http://github.com/alphagov/gds-sso)).


## Running the Application

The web application itself is run like any other Rails app, for example:
`script/rails s`

In development, you can run a DelayedJob worked to process background jobs:
`rake jobs:work`


## Implementation Notes

The application is divided into two parts: user management (User sign-on and passwords) and OAuth delegation (SSO service, contacts API).

Uesr management is handled by [Devise](https://github.com/plataformatec/devise). Configuration is in `config/initializers/devise` and views are either concrete (under app/views/devise) or pulled in from the Devise gem. Likewise with Controllers, though Devise controllers should inherit from `Devise::SomeController` (e.g., as with the `PasswordsController`).

API authentication is handled by Doorkeeper. It's a bit of a tricky beast, but not too bad overall, and it nicely separates concerns. Instead of exposing the current user with `current_user`, Doorkeeper exposes the current valid OAuth token as `doorkeeper_token`. Doorkeeper tokens are associated with a *resource owner* through an authenticator block, defined in `config/initializers/doorkeeper`.

To require Devise authentication in a controller (i.e., you want a user sitting at a computer looking at the page), add `before_filter :authenticate_user!` to the controller.

For example:

```ruby
class SettingsController
  before_filter :authenticate_user!

  def show
    settings = current_user.settings
  end
end
```

To require Doorkeeper authentication in a controller (i.e., you want an application that has been granted a token on behalf of a user to interact with the controller), add `doorkeeper_for :all` or `doorkeeper_for :action` to the controller.

For example:

```ruby
class AutomaticApiController
  doorkeeper_for :swizzle

  def swizzle
    @token_owning_user = User.find_by_id(doorkeeper_token.resource_owner_id)
  end
end
```

## Integrating with Sign-on-o-Tron

The OAuth flow you need to follow is:

1. User gives your app permission to request user data
2. App authenticates itself against Sign-on-o-Tron and gets `access_token`
3. App uses `access_token` to get user data and check for permissions to your app.

### User logs in to Sign-on-o-Tron II

Provide a `/sign_in` URL in your app which redirects the user to
`GET https://signonotron/oauth/authorize`.

The parameters required on this redirect are:

* `response_type` = `code`
* `redirect_uri` = `https://yourapp/authorized`
* `client_id` = [fooclient12]

After they authenticate with Sign-on-o-Tron, it will redirect them back
to `https://yourapp/authorized?code=12345` with an authorization
code.

### App authenticates itself with Sign-on-o-Tron

Your app does a `POST` behind the scenes to `https://signonotron/oauth/token`
with these parameters:

* `grant_type` = `authorization_code`
* `redirect_uri` = `https://yourapp/authorized`
* `code` = [12345]
* `client_id` = [fooclient12]
* `client_secret` = [super_secret]

Sign-on-o-Tron should return a `200` or `201` response including an access token
in a bit of JSON. Store that access token.

### Get user data from Sign-on-o-Tron

Make a request to `https://signonotron/user.json?access_token=your-stored-access-token&client_id=fooclient12`
to retrieve a JSON response including permissions for that user.
Check that the user is allowed to log in to your app. If yes, tell the user
that they're signed in.

### Examples

The [gds-sso](https://github.com/alphagov/gds-sso) gem is a Ruby
implementation of a Sign-on-o-Tron client. It implements the push API for
revoking permissions without waiting for session expiration.

[Backdrop](https://github.com/alphagov/backdrop) is a Python app for the
Performance Platform that uses Sign-on-o-Tron to authenticate users.
Authentication is handled in the `backdrop/write/` directory.
