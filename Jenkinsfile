#!/usr/bin/env groovy

node {
  def govuk = load '/var/lib/jenkins/groovy_scripts/govuk_jenkinslib.groovy'

  // These environment variables need to be defined for the assets:precompile step
  govuk.setEnvar("DEVISE_PEPPER", UUID.randomUUID().toString())
  govuk.setEnvar("DEVISE_SECRET_KEY", UUID.randomUUID().toString())

  // FIXME: Re-enable sass lint and fix the issues
  govuk.buildProject(sassLint: false)
}
