ENV["RAILS_ENV"] = "test"
ENV["PACT_DO_NOT_TRACK"] = "true"
require "active_support"
require "webmock"
require "pact/provider/rspec"
require "factory_bot_rails"

WebMock.disable!

Pact.configure do |config|
  config.reports_dir = "spec/reports/pacts"
  config.include WebMock::API
  config.include WebMock::Matchers
  config.include FactoryBot::Syntax::Methods
end

def url_encode(str)
  ERB::Util.url_encode(str)
end

Pact.service_provider "Signon API" do
  honours_pact_with "GDS API Adapters" do
    if ENV["PACT_URI"]
      pact_uri(ENV["PACT_URI"])
    else
      base_url = ENV.fetch("PACT_BROKER_BASE_URL", "https://govuk-pact-broker-6991351eca05.herokuapp.com")
      url = "#{base_url}/pacts/provider/#{url_encode(name)}/consumer/#{url_encode(consumer_name)}"

      pact_uri "#{url}/versions/#{url_encode(ENV.fetch('PACT_CONSUMER_VERSION', 'master'))}"
    end
  end
end

Pact.provider_states_for "GDS API Adapters" do
  set_up do
    DatabaseCleaner.clean_with :truncation
    GDS::SSO.test_user = create(:user, permissions: %w[signin])
  end

  tear_down do
    WebMock.disable!
  end

  provider_state "users exist with the UUIDs '9ef9779f-3cba-481a-9a73-00d39e33eb7b', 'b55873b4-bc83-4efe-bdc9-6b7d381a723e' and '64c7d994-17e0-44d9-97b0-87b43a581eb9'" do
    set_up do
      create(:user, uid: "9ef9779f-3cba-481a-9a73-00d39e33eb7b")
      create(:user, uid: "b55873b4-bc83-4efe-bdc9-6b7d381a723e")
      create(:user, uid: "64c7d994-17e0-44d9-97b0-87b43a581eb9")
    end
  end
end
