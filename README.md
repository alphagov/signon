# Sign-on-o-Tron II

This is a centralised OAuth 2-based single sign-on provider for GDS services.

We use [Devise](https://github.com/plataformatec/devise) to provide username / password sign-in, and [Doorkeeper](https://github.com/applicake/doorkeeper/) to provide an OAuth 2 provider.

Details of our interpretation of OAuth are provided in [an accompanying document](doc/oauth.md)

## Usage

The application has two rake tasks to create new users and client applications.

To create a new client application to which Sign-on-o-Tron will provide sign-on services:

`rake applications:create name=ClientName description="What does this app do" home_uri="https://myapp.com" redirect_uri="https://myapp.com/auth/gds/callback"`

This will create and return a client ID and secret that can be used in the app (normally via [GDS-SSO](http://github.com/alphagov/gds-sso)).

You can then add the ID and secret to the app's `ENV` using your preferred method.

To create a new user, use the following syntax:

`rake users:create name='First Last' email=user@example.com applications=Comma,Seperated,ListOf,Application,Names* [github=username] [twitter=username]`

\* You can also set the applications in a comma separated list via an `ENV['APPLICATIONS']` variable if you prefer.

## Getting this working in development.

More detail is contained in the [GDS-SSO Repo](https://github.com/alphagov/gds-sso#use-in-development-mode), but if you just want to get this working, follow the steps below:

* If you haven't already set real tokens in your app's `ENV`, you'll first need to run the following command to make sure your signonotron2 database has got OAuth config that matches what the apps use in development mode: <br /><br />`bundle exec ./script/make_oauth_work_in_dev`<br /><br />
* You must then make sure you set an environment variable when you run your app. e.g.: <br /><br />`GDS_SSO_STRATEGY=real bundle exec rails s`

### Creating new permissions

To create a new permission for an existing app, you first need to have the “superadmin” role on your account (or have access to someone who does): you’ll then be able to access the “Administer applications” menu item. Under the application you want to change, follow the “Supported Permissions” link and add a new permission from there.

Note that this UI won’t let you edit or delete existing permissions.


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
