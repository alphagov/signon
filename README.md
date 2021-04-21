# Signon

Signon is a centralised OAuth2 based single sign-on provider for GDS services that provides username/password and 2-Factor authentication.

## Technical documentation

[Devise] is used to provide username password sign-in, and [Doorkeeper] as an OAuth 2 provider. Details of our interpretation of OAuth are provided in [an accompanying document][auth].

This is a Ruby on Rails app, and should follow [our Rails app conventions][conventions].

You can use the [GOV.UK Docker environment][govuk-docker] to run the application and its tests with all the necessary dependencies. Follow the [usage instructions][docker-usage] to get started.

**Use GOV.UK Docker to run any commands that follow.**

### Running the test suite

```sh
bundle exec rake
```

## Further documentation

- [Usage documentation]
- [Mass password reset]
- [Troubleshooting]

## License

[MIT License](LICENCE)

[integration]: https://signon.integration.publishing.service.gov.uk
[conventions]: https://docs.publishing.service.gov.uk/manual/conventions-for-rails-applications.html
[govuk-docker]: https://github.com/alphagov/govuk-docker
[docker-usage]: https://github.com/alphagov/govuk-docker#usage
[Devise]: https://github.com/plataformatec/devise
[Doorkeeper]: https://github.com/applicake/doorkeeper
[auth]: docs/oauth.md
[Usage documentation]: docs/usage.md
[Mass password reset]: docs/mass_password_reset.md
[Troubleshooting]: docs/troubleshooting.md
