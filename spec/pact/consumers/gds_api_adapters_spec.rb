require "rails_helper"
require Rails.root.join("spec/support/pact/database_cleaner")
require Rails.root.join("spec/support/pact/auth")
require "pact/v2"
require "pact/v2/rspec"

RSpec.describe "Verify pacts from GDS API Adapter", :pact_v2 do
  Pact::V2.configure do |config|
    config.before_provider_state_setup do
      DatabaseCleaner.clean
      PactAuth.stub_access_token_creation!
      PactAuth.seed_bearer_token!
    end

    config.after_provider_state_teardown do
      DatabaseCleaner.clean
    end
  end

  http_pact_provider "Signon API", opts: {
    http_port: 9292,
    pact_uri: ENV["PACT_URI"],
    broker_url: ENV.fetch("PACT_BROKER_BASE_URL", "https://govuk-pact-broker-6991351eca05.herokuapp.com"),
    consumer_name: "GDS API Adapters",
    consumer_version_selectors: [
      { branch: ENV.fetch("PACT_CONSUMER_VERSION", "branch-main").delete_prefix("branch-") },
    ],
    log_level: :info,
    fail_if_no_pacts_found: true,
  }

  provider_state "users exist with the UUIDs 9ef9779f-3cba-481a-9a73-00d39e33eb7b, b55873b4-bc83-4efe-bdc9-6b7d381a723e and 64c7d994-17e0-44d9-97b0-87b43a581eb9" do
    set_up do
      FactoryBot.create(:user, uid: "9ef9779f-3cba-481a-9a73-00d39e33eb7b")
      FactoryBot.create(:user, uid: "b55873b4-bc83-4efe-bdc9-6b7d381a723e")
      FactoryBot.create(:user, uid: "64c7d994-17e0-44d9-97b0-87b43a581eb9")
    end
  end
end
