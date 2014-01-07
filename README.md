# Sign-on-o-Tron II

This is a centralised OAuth 2-based single sign-on provider for GDS services.

We use [Devise](https://github.com/plataformatec/devise) to provide username /
password sign-in, and [Doorkeeper](https://github.com/applicake/doorkeeper/) to
provide an OAuth 2 provider.

Details of our interpretation of OAuth are provided in
[an accompanying document](doc/oauth.md)

## Usage

The application has Rake tasks to create new users, client applications and API
clients.

To create a new client application to which Sign-on-o-Tron will provide sign-on
services:

```sh
rake applications:create name=ClientName description="What does this app do" \
home_uri="https://myapp.com" redirect_uri="https://myapp.com/auth/gds/callback"
```

This will create and return a client ID and secret that can be used in the app
(normally via [GDS-SSO](http://github.com/alphagov/gds-sso)).

You can then add the ID and secret to the app's `ENV` using your preferred
method.

To create a new user, use the following syntax:

```sh
rake users:create name='First Last' email=user@example.com \
applications=Comma,Seperated,ListOf,Application,Names* \
[github=username] [twitter=username]
```

\* You can also set the applications in a comma separated list via an
`ENV['APPLICATIONS']` variable if you prefer.

You may also need to create an API client, so one application can identify
itself to another. Say, for instance, you have an API that requires
authentication and you need to configure a frontend to make requests of it.
Assuming you have your application set up in Sign-on-o-tron under the name
"Stuff API", you will need to run the following command:

```sh
rake api_clients:create["Stuff Frontend","stuff-contact-email@example.com","Stuff API","signin"]
```

(`signin` is the implicit default permission for all apps.)

This command will give you an access token, which you can pass with requests to
the API. If you are using [our API adapters][api-adapters], you can pass this in
as the `bearer_token` argument. If not, you can set the HTTP header manually:

    Authorization: Bearer abcdef1234…

[api-adapters]: https://github.com/alphagov/gds-api-adapters

## Getting this working in development.

More detail is contained in the
[GDS-SSO Repo](https://github.com/alphagov/gds-sso#use-in-development-mode), but
if you just want to get this working, follow the steps below:

* If you haven't already set real tokens in your app's `ENV`, you'll first need
  to run the following command to make sure your signonotron2 database has got
  OAuth config that matches what the apps use in development mode:

  ```
  bundle exec ./script/make_oauth_work_in_dev
  ```
* You must then make sure you set an environment variable when you run your
  app. eg:

  ```
  GDS_SSO_STRATEGY=real bundle exec rails s
  ```

### Creating new permissions

To create a new permission for an existing app, you first need to have the
"superadmin" role on your account (or have access to someone who does): you'll
then be able to access the "Administer applications" menu item. Under the
application you want to change, follow the "Supported Permissions" link and add
a new permission from there.

Note that this UI won't let you edit or delete existing permissions.

## Running the Application

The web application itself is run like any other Rails app, for example:

```sh
script/rails s
```

In development, you can run sidekiq to process background jobs:

```sh
bundle exec sidekiq -C config/sidekiq.yml
```

## Implementation Notes

The application is divided into two parts: user management (User sign-on and
passwords) and OAuth delegation (SSO service, contacts API).

Uesr management is handled by
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
a computer looking at the page), add `before_filter:authenticate_user!` to the
controller.

For example:

```ruby
class SettingsController
  before_filter :authenticate_user!

  def show
    settings = current_user.settings
  end
end
```

To require Doorkeeper authentication in a controller (i.e., you want an
application that has been granted a token on behalf of a user to interact with
the controller), add `doorkeeper_for :all` or `doorkeeper_for :action` to the
controller.

For example:

```ruby
class AutomaticApiController
  doorkeeper_for :swizzle

  def swizzle
    @token_owning_user = User.find_by_id(doorkeeper_token.resource_owner_id)
  end
end
```
