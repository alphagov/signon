#!/usr/bin/env groovy

REPOSITORY = 'signonotron2'
DB_ADAPTERS = ['mysql', 'postgresql']

node {
  def govuk = load '/var/lib/jenkins/groovy_scripts/govuk_jenkinslib.groovy'

  properties([
    buildDiscarder(
      logRotator(
        numToKeepStr: '50')
      ),
    [$class: 'RebuildSettings', autoRebuild: false, rebuildDisabled: false],
    [$class: 'ThrottleJobProperty',
      categories: [],
      limitOneJobWithMatchingParams: true,
      maxConcurrentPerNode: 1,
      maxConcurrentTotal: 0,
      paramsToUseForLimit: 'Apps using "signonotron2_test" database',
      throttleEnabled: true,
      throttleOption: 'category'
    ],
  ])

  try {
    stage("Checkout") {
      checkout scm
    }

    stage("Clean up workspace") {
      govuk.cleanupGit()
    }

    stage("git merge") {
      govuk.mergeMasterBranch()
    }

    stage("bundle install") {
      govuk.bundleApp()
    }

    stage("rubylinter") {
      govuk.rubyLinter('app test lib spec config')
    }

    for (adapter in DB_ADAPTERS) {
      stage("Set up the DB") {
        sh("RAILS_ENV=test SIGNONOTRON2_DB_ADAPTER=${adapter} bundle exec rake db:drop db:create db:schema:load")
      }

      stage("Run tests") {
        sh("RAILS_ENV=test SIGNONOTRON2_DB_ADAPTER=${adapter} bundle exec rake --trace")
      }
    }

    if (env.BRANCH_NAME == 'master') {
      stage("Push release tag") {
        govuk.pushTag(REPOSITORY, env.BRANCH_NAME, 'release_' + env.BUILD_NUMBER)
      }

      stage("Deploy to integration") {
        govuk.deployIntegration(REPOSITORY, env.BRANCH_NAME, 'release', 'deploy')
      }
    }

  } catch (e) {
    currentBuild.result = "FAILED"
    step([$class: 'Mailer',
          notifyEveryUnstableBuild: true,
          recipients: 'govuk-ci-notifications@digital.cabinet-office.gov.uk',
          sendToIndividuals: true])
    throw e
  }
}
