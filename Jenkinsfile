#!/usr/bin/env groovy

library("govuk")

node("postgresql-9.3") {

  // These environment variables need to be defined for the assets:precompile step
  govuk.setEnvar("DEVISE_PEPPER", UUID.randomUUID().toString())
  govuk.setEnvar("DEVISE_SECRET_KEY", UUID.randomUUID().toString())

  // FIXME: Re-enable sass lint and fix the issues
  govuk.buildProject(sassLint: false, brakeman: true, rubyLintDiff: false)
}
