#!/usr/bin/env groovy

library("govuk")

node {
  // These environment variables need to be defined for the assets:precompile step
  govuk.setEnvar("DEVISE_PEPPER", UUID.randomUUID().toString())
  govuk.setEnvar("DEVISE_SECRET_KEY", UUID.randomUUID().toString())

  govuk.buildProject(
    brakeman: true,
  )

  // Run against the MySQL 8 Docker instance on GOV.UK CI
  govuk.setEnvar("TEST_DATABASE_URL", "mysql2://root:root@127.0.0.1:33068/signonotron2_test")
}
