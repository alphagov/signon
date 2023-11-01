desc "Run all linters"
task lint: :environment do
  sh "yarn run lint"
  sh "bundle exec brakeman . --except CheckRenderInline --quiet"
  sh "bundle exec rubocop"
end
