# Environment variables

## ActiveRecord Encryption

Used by ActiveRecord to encrypt values in the database e.g. `User#otp_secret_key`.

* `ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT`
* `ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY`

## Devise

Used by Devise and/or its extensions to encrypt values in the database e.g. `User#password`.

* `DEVISE_PEPPER`
* `DEVISE_SECRET_KEY`

## GOV.UK Notify

Used to configure Mail::Notify for use by ActionMailer in sending emails.

* `GOVUK_NOTIFY_API_KEY`
* `GOVUK_NOTIFY_TEMPLATE_ID`

## Rewrite URIs for OAuth Applications

Used by `Doorkeeper::Application#substituted_uri`.

* `SIGNON_APPS_URI_SUB_PATTERN`
* `SIGNON_APPS_URI_SUB_REPLACEMENT`

## GOV.UK app domain

Used to configure Google Analytics in the new `app/views/layouts/admin_layout.html.erb`.

* `GOVUK_APP_DOMAIN`

## GOV.UK environment names

Used to configure `GovukAdminTemplate` and in `Healthcheck::ApiTokens#expiring_tokens`.

* `GOVUK_ENVIRONMENT`
