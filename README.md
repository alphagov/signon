# Signon

Signin is a centralised OAuth2 based single sign-on provider for GDS services
that provides username/password and 2-Factor authentication.

## Live example

[Integration Environment Signon](https://signon.integration.publishing.service.gov.uk)

## Technical documentation

[Devise](https://github.com/plataformatec/devise) is used to provide username 
password sign-in, and [Doorkeeper](https://github.com/applicake/doorkeeper/)
as an OAuth 2 provider.

Details of our interpretation of OAuth are provided in
[an accompanying document](doc/oauth.md)

## Dependencies

[Various Rubygems](Gemfile)

MySQL or Postgres for main data storage. We use MySQL in GOV.UK Production

Redis/Sidekiq for ActiveJob asynchronous tasks

## Running the application

The web application itself is run like any other Rails app, for example:

```sh
script/rails s
```

In development, you can run sidekiq to process background jobs:

```sh
bundle exec sidekiq -C config/sidekiq.yml
```

## Running the test suite

```sh
bundle exec rake
```

## Setup and usage

See accompanying [Usage Documentation](doc/usage.md)

## License

[MIT License](LICENCE)


