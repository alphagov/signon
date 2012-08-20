# Sign-on-o-Tron II

This is a centralised OAuth 2-based single sign-on provider for GDS services.

We use [Devise](https://github.com/plataformatec/devise) to provide username / password sign-in, and [Doorkeeper](https://github.com/applicake/doorkeeper/) to provide an OAuth 2 provider.

## Usage

The application has two rake tasks to create new users and client applications.

To create a new user, use the following syntax:

`rake users:create name='First Last' email=user@example.com [github=username] [twitter=username]`

To create a new client application to which Sign-on-o-Tron will provide sign-on services:

`rake clients:create name=ClientName description="What does this app do" home_uri="https://myapp.com"`

which will create and return a client ID and secret that can be used in the app (normally via [GDS-SSO](http://github.com/alphagov/gds-sso)).

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
