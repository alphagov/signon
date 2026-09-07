module CustomGeneratorArgs
module_function

  def generate(_opts = {})
    "SOME_BEARER_TOKEN"
  end
end

module PactAuth
module_function

  def stub_access_token_creation!
    Doorkeeper.configure do
      access_token_generator "CustomGeneratorArgs"
    end
  end

  def seed_bearer_token!
    application = FactoryBot.create(:application, name: "Signon API")
    user = FactoryBot.create(:api_user, with_permissions: { application => [SupportedPermission::SIGNIN_NAME] })
    Doorkeeper::AccessToken.create!(resource_owner_id: user.id, application_id: application.id)
  end
end
