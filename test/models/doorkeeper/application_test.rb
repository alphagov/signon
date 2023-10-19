require "test_helper"

class Doorkeeper::ApplicationTest < ActiveSupport::TestCase
  should "have a signin supported permission on create" do
    assert_not_nil create(:application).signin_permission
  end

  context "user_update_permission" do
    should "not be grantable from ui" do
      user_update_permission = create(:application, supports_push_updates: true).supported_permissions.detect { |perm| perm.name == "user_update_permission" }
      assert_not user_update_permission.grantable_from_ui?
    end

    should "be created after save if application supports push updates" do
      application = create(:application, supports_push_updates: false)
      application.update!(supports_push_updates: true)

      application.reload
      assert_includes application.supported_permission_strings, "user_update_permission"
    end

    should "not be created after save if application doesn't support push updates" do
      assert_not_includes create(:application, supports_push_updates: false).supported_permission_strings, "user_update_permission"
    end
  end

  context "supported_permission_strings" do
    should "return a list of string permissions" do
      user = create(:user)
      app = create(:application, with_supported_permissions: %w[write])

      assert_equal [SupportedPermission::SIGNIN_NAME, "write"], app.supported_permission_strings(user)
    end

    should "only show permissions that super organisation admins themselves have" do
      app = create(:application, with_delegatable_supported_permissions: %w[write approve])
      super_org_admin = create(:super_organisation_admin_user, with_permissions: { app => %w[write] })

      assert_equal %w[write], app.supported_permission_strings(super_org_admin)
    end

    should "only show delegatable permissions to super organisation admins" do
      super_org_admin = create(:super_organisation_admin_user)
      app = create(:application, with_delegatable_supported_permissions: %w[write], with_supported_permissions: %w[approve])
      super_org_admin.grant_application_permissions(app, %w[write approve])

      assert_equal %w[write], app.supported_permission_strings(super_org_admin)
    end

    should "only show permissions that organisation admins themselves have" do
      app = create(:application, with_delegatable_supported_permissions: %w[write approve])
      organisation_admin = create(:organisation_admin_user, with_permissions: { app => %w[write] })

      assert_equal %w[write], app.supported_permission_strings(organisation_admin)
    end

    should "only show delegatable permissions to organisation admins" do
      user = create(:organisation_admin_user)
      app = create(:application, with_delegatable_supported_permissions: %w[write], with_supported_permissions: %w[approve])
      user.grant_application_permissions(app, %w[write approve])

      assert_equal %w[write], app.supported_permission_strings(user)
    end
  end

  context "redirect_uri" do
    should "return application redirect uri" do
      application = create(:application)

      assert_equal "https://app.com/callback", application.redirect_uri
    end

    should "return application substituted redirect uri if match" do
      Rails.application.config.stubs(oauth_apps_uri_sub_pattern: "replace.me")
      Rails.application.config.stubs(oauth_apps_uri_sub_replacement: "new.domain")

      application = create(:application, redirect_uri: "https://app.replace.me/callback")

      assert_equal "https://app.new.domain/callback", application.redirect_uri
    end

    should "return application original redirect uri if not matched" do
      Rails.application.config.stubs(oauth_apps_uri_sub_pattern: "replace.me")
      Rails.application.config.stubs(oauth_apps_uri_sub_replacement: "new.domain")

      application = create(:application, redirect_uri: "https://app.keep.me/callback")

      assert_equal "https://app.keep.me/callback", application.redirect_uri
    end
  end

  context "home_uri" do
    should "return application home uri" do
      application = create(:application)

      assert_equal "https://app.com/", application.home_uri
    end

    should "return application substituted home uri if match" do
      Rails.application.config.stubs(oauth_apps_uri_sub_pattern: "replace.me")
      Rails.application.config.stubs(oauth_apps_uri_sub_replacement: "new.domain")

      application = create(:application, home_uri: "https://app.replace.me/")

      assert_equal "https://app.new.domain/", application.home_uri
    end

    should "return application original home uri if not matched" do
      Rails.application.config.stubs(oauth_apps_uri_sub_pattern: "replace.me")
      Rails.application.config.stubs(oauth_apps_uri_sub_replacement: "new.domain")

      application = create(:application, home_uri: "https://app.keep.me/")

      assert_equal "https://app.keep.me/", application.home_uri
    end
  end

  context "sorted_supported_permissions_grantable_from_ui" do
    should "return all of the supported permissions that are grantable from the ui" do
      application = create(
        :application,
        name: "Whitehall",
        with_supported_permissions: ["Editor", SupportedPermission::SIGNIN_NAME],
        with_supported_permissions_not_grantable_from_ui: ["Not grantable"],
      )

      permission_names = application.sorted_supported_permissions_grantable_from_ui.map(&:name)

      assert permission_names.include?("Editor")
      assert permission_names.include?(SupportedPermission::SIGNIN_NAME)
      assert_not permission_names.include?("Not grantable")
    end

    should "sort the permissions alphabetically by name, but with the signin permission first" do
      application = create(
        :application,
        name: "Whitehall",
        with_supported_permissions: ["Writer", "Editor", SupportedPermission::SIGNIN_NAME],
      )

      permission_names = application.sorted_supported_permissions_grantable_from_ui.map(&:name)

      assert_equal [SupportedPermission::SIGNIN_NAME, "Editor", "Writer"], permission_names
    end
  end

  context ".all (default scope)" do
    setup do
      @app = create(:application)
    end

    should "include apps that have not been retired" do
      @app.update!(retired: false)
      assert_equal [@app], Doorkeeper::Application.all
    end

    should "exclude apps that have been retired" do
      @app.update!(retired: true)
      assert_equal [], Doorkeeper::Application.all
    end
  end

  context ".retired" do
    setup do
      @app = create(:application)
    end

    should "include apps that have been retired" do
      @app.update!(retired: true)
      assert_equal [@app], Doorkeeper::Application.unscoped.retired
    end

    should "exclude apps that have not been retired" do
      @app.update!(retired: false)
      assert_equal [], Doorkeeper::Application.unscoped.retired
    end
  end

  context ".not_retired" do
    setup do
      @app = create(:application)
    end

    should "include apps that have not been retired" do
      @app.update!(retired: false)
      assert_equal [@app], Doorkeeper::Application.not_retired
    end

    should "exclude apps that have been retired" do
      @app.update!(retired: true)
      assert_equal [], Doorkeeper::Application.not_retired
    end
  end

  context ".not_api_only" do
    setup do
      @app = create(:application)
    end

    should "include apps that are not api only" do
      @app.update!(api_only: false)
      assert_equal [@app], Doorkeeper::Application.not_api_only
    end

    should "exclude apps that are api only" do
      @app.update!(api_only: true)
      assert_equal [], Doorkeeper::Application.not_api_only
    end
  end

  context ".can_signin" do
    should "return applications that the user can signin into" do
      user = create(:user)
      application = create(:application)
      user.grant_application_signin_permission(application)

      assert_includes Doorkeeper::Application.can_signin(user), application
    end

    should "not return applications that are retired" do
      user = create(:user)
      application = create(:application, retired: true)
      user.grant_application_signin_permission(application)

      assert_empty Doorkeeper::Application.can_signin(user)
    end

    should "not return applications that the user can't signin into" do
      user = create(:user)
      create(:application)

      assert_empty Doorkeeper::Application.can_signin(user)
    end
  end

  context ".with_signin_delegatable" do
    should "return applications that support delegation of signin permission" do
      application = create(:application, with_delegatable_supported_permissions: [SupportedPermission::SIGNIN_NAME])

      assert_includes Doorkeeper::Application.with_signin_delegatable, application
    end

    should "not return applications that don't support delegation of signin permission" do
      create(:application, with_supported_permissions: [SupportedPermission::SIGNIN_NAME])

      assert_empty Doorkeeper::Application.with_signin_delegatable
    end
  end

  context ".with_signin_permission_for" do
    setup do
      @user = create(:user)
      @app = create(:application)
    end

    should "include applications the user has the signin permission for" do
      @user.grant_application_signin_permission(@app)

      assert_equal [@app], Doorkeeper::Application.with_signin_permission_for(@user)
    end

    should "exclude applications the user does not have the signin permission for" do
      create(:supported_permission, application: @app, name: "not-signin")

      @user.grant_application_permission(@app, %w[not-signin])

      assert_equal [], Doorkeeper::Application.with_signin_permission_for(@user)
    end
  end

  context ".without_signin_permission_for" do
    setup do
      @user = create(:user)
      @app = create(:application)
    end

    should "exclude applications the user has the signin permission for" do
      @user.grant_application_signin_permission(@app)

      assert_equal [], Doorkeeper::Application.without_signin_permission_for(@user)
    end

    should "include applications the user does not have the signin permission for" do
      create(:supported_permission, application: @app, name: "not-signin")

      @user.grant_application_permission(@app, %w[not-signin])

      assert_equal [@app], Doorkeeper::Application.without_signin_permission_for(@user)
    end

    should "include applications the user doesn't have any permissions for" do
      assert_equal [@app], Doorkeeper::Application.without_signin_permission_for(@user)
    end
  end

  context ".ordered_by_name" do
    should "return applications ordered by name" do
      application_named_foo = create(:application, name: "Foo")
      application_named_bar = create(:application, name: "Bar")

      applications = Doorkeeper::Application.ordered_by_name

      assert_equal [application_named_bar, application_named_foo], applications
    end
  end
end
