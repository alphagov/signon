require 'test_helper'

class ::Doorkeeper::ApplicationTest < ActiveSupport::TestCase

  should "have a signin supported permission on create" do
    assert_not_nil create(:application).signin_permission
  end

  context "supported_permission_strings" do

    should "return a list of string permissions" do
      user = create(:user)
      app = create(:application, with_supported_permissions: ["write"])

      assert_equal ["signin", "write"], app.supported_permission_strings(user)
    end

    should "only show permissions that organisation admins themselves have" do
      app = create(:application, with_delegatable_supported_permissions: ["write", "approve"])
      user = create(:organisation_admin, with_permissions: { app => ["write"] })

      assert_equal ["write"], app.supported_permission_strings(user)
    end

    should "only show delegatable permissions to organisation admins" do
      user = create(:organisation_admin)
      app = create(:application, supported_permissions: [
        create(:delegatable_supported_permission, name: "write"),
        create(:non_delegatable_supported_permission, name: "approve")
      ])
      create(:permission, user: user, application: app, permissions: ['write', 'approve'])

      assert_equal ["write"], app.supported_permission_strings(user)
    end

  end

  context "scopes" do
    should "return applications that the user can signin into" do
      user = create(:user)
      application = create(:application)
      permission = create(:permission, permissions: ['signin'], user: user, application: application)

      assert_include Doorkeeper::Application.can_signin(user), application
    end

    should "not return applications that the user can't signin into" do
      user = create(:user)
      application = create(:application)
      permission = create(:permission, permissions: ['signin'],
                    user: create(:user), application: application)

      assert_empty Doorkeeper::Application.can_signin(user)
    end

    should "return applications that support delegation of signin permission" do
      application = create(:application, with_delegatable_supported_permissions: ['signin'])

      assert_include Doorkeeper::Application.with_signin_delegatable, application
    end

    should "not return applications that don't support delegation of signin permission" do
      application = create(:application, with_supported_permissions: ['signin'])

      assert_empty Doorkeeper::Application.with_signin_delegatable
    end
  end
end
