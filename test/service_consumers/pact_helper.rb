ENV["RAILS_ENV"] = "test"
ENV["PACT_DO_NOT_TRACK"] = "true"
require "active_support"
require "webmock"
require "pact/provider/rspec"
require "factory_bot_rails"

module CustomGeneratorArgs
  def self.generate(_opts = {})
    "SOME_BEARER_TOKEN"
  end
end

WebMock.disable!

Pact.configure do |config|
  config.reports_dir = "spec/reports/pacts"
  config.include WebMock::API
  config.include WebMock::Matchers
  config.include FactoryBot::Syntax::Methods
end

def stub_access_token_creation!
  # This stubs Doorkeeper so can ensure the token we generate is predictable, so we can run
  # the Pact tests with a dummy bearer token
  Doorkeeper.configure do
    access_token_generator "CustomGeneratorArgs"
  end
end

Pact.service_provider "Signon API" do
  include ERB::Util

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
    stub_access_token_creation!
    application = create(:application, name: "Signon API")
    user = create(:api_user, with_permissions: { application => [SupportedPermission::SIGNIN_NAME] })
    Doorkeeper::AccessToken.create!(resource_owner_id: user.id, application_id: application.id)
  end

  provider_state "users exist with the UUIDs 9ef9779f-3cba-481a-9a73-00d39e33eb7b, b55873b4-bc83-4efe-bdc9-6b7d381a723e and 64c7d994-17e0-44d9-97b0-87b43a581eb9" do
    set_up do
      create(:user, uid: "9ef9779f-3cba-481a-9a73-00d39e33eb7b")
      create(:user, uid: "b55873b4-bc83-4efe-bdc9-6b7d381a723e")
      create(:user, uid: "64c7d994-17e0-44d9-97b0-87b43a581eb9")
    end
  end
end
