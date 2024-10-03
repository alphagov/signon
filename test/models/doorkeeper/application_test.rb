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
      assert_includes application.supported_permissions.pluck(:name), "user_update_permission"
    end

    should "not be created after save if application doesn't support push updates" do
      assert_not_includes create(:application, supports_push_updates: false).supported_permissions.pluck(:name), "user_update_permission"
    end
  end

  context "#redirect_uri" do
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

  context "#home_uri" do
    should "return application home uri" do
      application = create(:application)

      assert_equal "https://app.com/", application.home_uri
    end

    context "when URI substitution is enabled" do
      setup do
        Rails.application.config.stubs(oauth_apps_uri_sub_pattern: "replace.me")
        Rails.application.config.stubs(oauth_apps_uri_sub_replacement: "new.domain")
      end

      should "return nil if application home uri is nil" do
        application = create(:application, home_uri: nil)

        assert_nil application.home_uri
      end

      should "return application substituted home uri if match" do
        application = create(:application, home_uri: "https://app.replace.me/")

        assert_equal "https://app.new.domain/", application.home_uri
      end

      should "return application original home uri if not matched" do
        application = create(:application, home_uri: "https://app.keep.me/")

        assert_equal "https://app.keep.me/", application.home_uri
      end
    end
  end

  context "#sorted_supported_permissions_grantable_from_ui" do
    setup do
      @application = create(:application)
      @delegated_permission = create(:delegated_supported_permission, application: @application)
      @delegated_non_grantable_permission = create(:delegated_supported_permission, application: @application, grantable_from_ui: false)
      @non_delegated_permission = create(:non_delegated_supported_permission, application: @application)
      @non_delegated_non_grantable_permission = create(:non_delegated_supported_permission, application: @application, grantable_from_ui: false)

      @sorted_permissions = "double"
    end

    should "sorts the app's UI-grantable permissions using `SupportedPermission`" do
      SupportedPermission
        .expects(:sort_with_signin_first)
        .with { |value|
          assert_same_elements(
            [@application.signin_permission, @delegated_permission, @non_delegated_permission],
            value,
          )
        }
        .returns(@sorted_permissions)

      assert_equal @sorted_permissions, @application.sorted_supported_permissions_grantable_from_ui
    end

    should "exclude the signin permission if requested" do
      SupportedPermission
        .expects(:sort_with_signin_first)
        .with { |value|
          assert_same_elements(
            [@delegated_permission, @non_delegated_permission],
            value,
          )
        }
        .returns(@sorted_permissions)

      assert_equal @sorted_permissions, @application.sorted_supported_permissions_grantable_from_ui(include_signin: false)
    end

    should "exclude non-delegated permissions if requested" do
      SupportedPermission
        .expects(:sort_with_signin_first)
        .with { |value|
          assert_same_elements(
            [@application.signin_permission, @delegated_permission],
            value,
          )
        }
        .returns(@sorted_permissions)

      assert_equal @sorted_permissions, @application.sorted_supported_permissions_grantable_from_ui(only_delegated: true)
    end

    should "exclude signin and non-delegated permissions if requested" do
      SupportedPermission
        .expects(:sort_with_signin_first)
        .with { |value| assert_same_elements([@delegated_permission], value) }
        .returns(@sorted_permissions)

      assert_equal @sorted_permissions, @application.sorted_supported_permissions_grantable_from_ui(include_signin: false, only_delegated: true)
    end
  end

  context "has_non_signin_permissions_grantable_from_ui?" do
    should "return false if no permissions are grantable from the UI" do
      app = create(
        :application,
        with_delegated_supported_permissions: [],
        with_delegated_supported_permissions_not_grantable_from_ui: %w[non-grantable],
        with_non_delegated_supported_permissions: [],
        with_non_delegated_supported_permissions_not_grantable_from_ui: %w[non-delegated-non-grantable],
      )

      assert_not app.has_non_signin_permissions_grantable_from_ui?
    end

    should "return false if only the signin permission is grantable from the UI" do
      app_1 = create(
        :application,
        with_delegated_supported_permissions: [SupportedPermission::SIGNIN_NAME],
        with_delegated_supported_permissions_not_grantable_from_ui: %w[non-grantable],
        with_non_delegated_supported_permissions: [],
        with_non_delegated_supported_permissions_not_grantable_from_ui: %w[non-delegated-non-grantable],
      )

      app_2 = create(
        :application,
        with_delegated_supported_permissions: [],
        with_delegated_supported_permissions_not_grantable_from_ui: %w[non-grantable],
        with_non_delegated_supported_permissions: [SupportedPermission::SIGNIN_NAME],
        with_non_delegated_supported_permissions_not_grantable_from_ui: %w[non-delegated-non-grantable],
      )

      assert_not app_1.has_non_signin_permissions_grantable_from_ui?
      assert_not app_2.has_non_signin_permissions_grantable_from_ui?
    end

    should "return true if there are non-signin permissions grantable from the UI" do
      app_1 = create(
        :application,
        with_delegated_supported_permissions: %w[yay!],
        with_delegated_supported_permissions_not_grantable_from_ui: %w[non-grantable],
        with_non_delegated_supported_permissions: [],
        with_non_delegated_supported_permissions_not_grantable_from_ui: %w[non-delegated-non-grantable],
      )
      app_2 = create(
        :application,
        with_delegated_supported_permissions: [],
        with_delegated_supported_permissions_not_grantable_from_ui: %w[non-grantable],
        with_non_delegated_supported_permissions: %w[yay!],
        with_non_delegated_supported_permissions_not_grantable_from_ui: %w[non-delegated-non-grantable],
      )

      assert app_1.has_non_signin_permissions_grantable_from_ui?
      assert app_2.has_non_signin_permissions_grantable_from_ui?
    end
  end

  context "has_delegated_non_signin_permissions_grantable_from_ui?" do
    should "return false if no permissions are delegated" do
      app = create(
        :application,
        with_delegated_supported_permissions: [],
        with_delegated_supported_permissions_not_grantable_from_ui: [],
        with_non_delegated_supported_permissions: %w[non-delegated],
        with_non_delegated_supported_permissions_not_grantable_from_ui: %w[non-delegated-non-grantable],
      )

      assert_not app.has_delegated_non_signin_permissions_grantable_from_ui?
    end

    should "return false if no permissions are grantable from the UI" do
      app = create(
        :application,
        with_delegated_supported_permissions: [],
        with_delegated_supported_permissions_not_grantable_from_ui: %w[non-grantable],
        with_non_delegated_supported_permissions: [],
        with_non_delegated_supported_permissions_not_grantable_from_ui: %w[non-delegated-non-grantable],
      )

      assert_not app.has_delegated_non_signin_permissions_grantable_from_ui?
    end

    should "return false if only the signin permission is delegated and grantable from the UI" do
      app = create(
        :application,
        with_delegated_supported_permissions: [SupportedPermission::SIGNIN_NAME],
        with_delegated_supported_permissions_not_grantable_from_ui: %w[non-grantable],
        with_non_delegated_supported_permissions: %w[non-delegated],
        with_non_delegated_supported_permissions_not_grantable_from_ui: %w[non-delegated-non-grantable],
      )

      assert_not app.has_delegated_non_signin_permissions_grantable_from_ui?
    end

    should "return true if there are delegated non-signin permissions grantable from the UI" do
      app = create(
        :application,
        with_delegated_supported_permissions: %w[yay!],
        with_delegated_supported_permissions_not_grantable_from_ui: %w[non-grantable],
        with_non_delegated_supported_permissions: %w[non-delegated],
        with_non_delegated_supported_permissions_not_grantable_from_ui: %w[non-delegated-non-grantable],
      )

      assert app.has_delegated_non_signin_permissions_grantable_from_ui?
    end
  end

  context "has_non_delegated_non_signin_permissions_grantable_from_ui?" do
    should "return false if no permissions are non-delegated" do
      app = create(
        :application,
        with_delegated_supported_permissions: %w[delegtable],
        with_delegated_supported_permissions_not_grantable_from_ui: %w[delegated-non-grantable],
        with_non_delegated_supported_permissions: [],
        with_non_delegated_supported_permissions_not_grantable_from_ui: [],
      )

      assert_not app.has_non_delegated_non_signin_permissions_grantable_from_ui?
    end

    should "return false if no permissions are grantable from the UI" do
      app = create(
        :application,
        with_delegated_supported_permissions: [],
        with_delegated_supported_permissions_not_grantable_from_ui: %w[non-grantable],
        with_non_delegated_supported_permissions: [],
        with_non_delegated_supported_permissions_not_grantable_from_ui: %w[non-delegated-non-grantable],
      )

      assert_not app.has_non_delegated_non_signin_permissions_grantable_from_ui?
    end

    should "return false if only the signin permission is non-delegated and grantable from the UI" do
      app = create(
        :application,
        with_delegated_supported_permissions: %w[delegated],
        with_delegated_supported_permissions_not_grantable_from_ui: %w[non-grantable],
        with_non_delegated_supported_permissions: [SupportedPermission::SIGNIN_NAME],
        with_non_delegated_supported_permissions_not_grantable_from_ui: %w[non-delegated-non-grantable],
      )

      assert_not app.has_non_delegated_non_signin_permissions_grantable_from_ui?
    end

    should "return true if there are non-delegated non-signin permissions grantable from the UI" do
      app = create(
        :application,
        with_delegated_supported_permissions: %w[delegated],
        with_delegated_supported_permissions_not_grantable_from_ui: %w[non-grantable],
        with_non_delegated_supported_permissions: %w[yay!],
        with_non_delegated_supported_permissions_not_grantable_from_ui: %w[non-delegated-non-grantable],
      )

      assert app.has_non_delegated_non_signin_permissions_grantable_from_ui?
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

  context ".api_only" do
    setup do
      @app = create(:application)
    end

    should "include apps that are api only" do
      @app.update!(api_only: true)
      assert_equal [@app], Doorkeeper::Application.api_only
    end

    should "exclude apps that are not api only" do
      @app.update!(api_only: false)
      assert_equal [], Doorkeeper::Application.api_only
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

  context ".with_home_uri" do
    setup do
      @app = create(:application)
    end

    should "include apps that have a home URI" do
      @app.update!(home_uri: "http://gov.uk")
      assert_equal [@app], Doorkeeper::Application.with_home_uri
    end

    should "exclude apps that has a nil home URI" do
      @app.update!(home_uri: nil)
      assert_equal [], Doorkeeper::Application.with_home_uri
    end

    should "exclude apps that has a blank home URI" do
      @app.update!(home_uri: "")
      assert_equal [], Doorkeeper::Application.with_home_uri
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

  context ".with_signin_delegated" do
    should "return applications that support delegation of signin permission" do
      application = create(:application, with_delegated_supported_permissions: [SupportedPermission::SIGNIN_NAME])

      assert_includes Doorkeeper::Application.with_signin_delegated, application
    end

    should "not return applications that don't support delegation of signin permission" do
      create(:application, with_non_delegated_supported_permissions: [SupportedPermission::SIGNIN_NAME])

      assert_empty Doorkeeper::Application.with_signin_delegated
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
