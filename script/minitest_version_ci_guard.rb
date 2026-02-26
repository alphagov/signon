require "bundler"

lockfile = Bundler::LockfileParser.new(
  Bundler.read_file("Gemfile.lock"),
)

def gem_version(lockfile, name)
  spec = lockfile.specs.find { |s| s.name == name }
  spec&.version
end

rails_version = gem_version(lockfile, "rails")
minitest_version = gem_version(lockfile, "minitest")

if rails_version.nil? || minitest_version.nil?
  puts "Could not determine Rails or Minitest version."
  exit 1
end

if Gem::Version.new(rails_version) >= Gem::Version.new("8.1.0") &&
    Gem::Version.new(minitest_version) < Gem::Version.new("6.0.0")

  puts <<~MSG
    ❌ CI GUARD FAILURE

    Rails is #{rails_version}, which should support Minitest 6.
    But Minitest is still pinned to #{minitest_version}.

    Please un-do changes included in https://github.com/alphagov/signon/pull/4443/changes:
      - Remove the '~> 5' pin in Gemfile
      - Remove the Dependabot ignore for 6.x
      - Upgrade to Minitest 6
      - Remove this CI check
  MSG

  exit 1
end

puts "✅ Minitest/Rails compatibility guard passed."
