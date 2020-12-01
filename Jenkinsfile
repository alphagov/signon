#!/usr/bin/env groovy

library("govuk")

node {
  // These environment variables need to be defined for the assets:precompile step
  govuk.setEnvar("DEVISE_PEPPER", UUID.randomUUID().toString())
  govuk.setEnvar("DEVISE_SECRET_KEY", UUID.randomUUID().toString())

  govuk.buildProject(
    beforeTest: { sh("yarn install") },
    brakeman: true,
    sassLint: false,
  )
}
