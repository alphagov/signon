# Signon

Signon is a centralised, OAuth2-based single sign-on (SSO) provider for GDS services that provides username/password and 2-factor authentication.

Signon uses [Devise] for username/password sign-in, and [Doorkeeper] as an OAuth 2 provider. Details of our interpretation of OAuth are provided in [an accompanying document](docs/oauth.md).

Signon is a Ruby on Rails app and should follow [our Rails app conventions][conventions].

[Devise]: https://github.com/heartcombo/devise
[Doorkeeper]: https://github.com/doorkeeper-gem/doorkeeper
[conventions]: https://docs.publishing.service.gov.uk/manual/conventions-for-rails-applications.html


## Running the test suite using GOV.UK Docker

You can use the [GOV.UK Docker environment][govuk-docker] to run the application, its tests and all its dependencies. Follow the [govuk-docker installation instructions][govuk-docker-install] to get started.

The first build with GOV.UK Docker typically takes 5-20 minutes, depending on your computer and network connection.

```sh
cd govuk-docker
make signon  # This step can take a few minutes, especially the first time.
govuk-docker run signon-lite bundle exec rake  # Run all tests.
```

[govuk-docker]: https://github.com/alphagov/govuk-docker
[govuk-docker-install]: https://github.com/alphagov/govuk-docker#usage


## Running the test suite without Docker

You may find it more convenient to run the tests without Docker, for example if your machine has limited Internet connectivity or less than 16 GB RAM, or if you just want to run some subset of the tests.

The tests require Redis, MySQL and Chromedriver. On macOS you can install and run these using [Homebrew](https://brew.sh/).

```sh
brew install chromedriver mysql redis
brew services start mysql
brew services start redis
```

Build Signon and create the database test fixtures.

```sh
export TEST_DATABASE_URL='mysql2://root:root@127.0.0.1/signon'
export DATABASE_URL="$TEST_DATABASE_URL"
bundle install -j12
bundle exec rails db:reset
```

Run all the tests.

```sh
bundle exec rake
```

Run only the tests in a specific file which match a regex.

```sh
bundle exec rake test TEST=test/lib/kubernetes/client_test.rb TESTOPTS='-n "/should call apply secret/"'
```

When finished, you may want to shut down the MySQL and Redis servers.

```sh
brew services stop redis
brew services stop mysql
```

## Further documentation

- [Usage documentation](docs/usage.md)
- [Mass password reset](docs/mass_password_reset.md)
- [Troubleshooting](docs/troubleshooting.md)


## Licence

[MIT Licence](LICENCE)
