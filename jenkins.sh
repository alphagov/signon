#!/bin/bash -x

set -e

git clean -fdx

export USE_SIMPLECOV=true
export RAILS_ENV=test
bundle install --path "${HOME}/bundles/${JOB_NAME}" --deployment

# Lint changes introduced in this branch, but not for master
if [[ ${GIT_BRANCH} != "origin/master" ]]; then
  bundle exec govuk-lint-ruby \
    --diff \
    --cached \
    --format html --out rubocop-${GIT_COMMIT}.html \
    --format clang \
    app test lib spec
fi

bundle exec rake stats
bundle exec rake db:drop db:create db:schema:load
bundle exec rake --trace
