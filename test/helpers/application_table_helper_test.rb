require "test_helper"

class ApplicationTableHelperTest < ActionView::TestCase
  include PunditHelpers

  context "#wrap_links_in_actions_markup" do
    should "wrap an array of links in a container with a class to apply actions styles" do
      links = [
        "<a class=\"govuk-link\" href=\"https://www.gov.uk/destination-one\">Destination one</a>",
        "<a class=\"govuk-link\" href=\"https://www.gov.uk/destination-two\">Destination two</a>",
      ]

      expected_output = "<div class=\"govuk-table__actions\">
        <a class=\"govuk-link\" href=\"https://www.gov.uk/destination-one\">Destination one</a>
        <a class=\"govuk-link\" href=\"https://www.gov.uk/destination-two\">Destination two</a>
      </div>".gsub(/>\s+</, "><")

      assert_equal expected_output, wrap_links_in_actions_markup(links)
    end
  end

  context "#account_applications_grant_access_link" do
    setup do
      @user = build(:user)
      stubs(:current_user).returns(@user)
      @application = create(:application)
    end

    should "generate a grant access button when the current user can grant the signin permission" do
      stub_policy @user, [:account, Doorkeeper::Application], grant_signin_permission?: true
      assert_includes account_applications_grant_access_link(@application), "Grant access"
    end

    should "return an empty string when the current user cannot grant the signin permission" do
      stub_policy @user, [:account, Doorkeeper::Application], grant_signin_permission?: false
      assert account_applications_grant_access_link(@application).empty?
    end
  end

  context "#users_applications_grant_access_link" do
    setup do
      @application = create(:application)
      @current_user = build(:user)
      stubs(:current_user).returns(@current_user)
      @grantee = create(:user)
      @record = { application: @application, user: @grantee }
    end

    should "generate a grant access button when the current user can grant the signin permission" do
      stub_policy(
        @current_user,
        @record,
        policy_class: Users::ApplicationPolicy,
        grant_signin_permission?: true,
      )

      assert_includes users_applications_grant_access_link(@application, @grantee), "Grant access"
    end

    should "return an empty string when the current user cannot grant the signin permission" do
      stub_policy(
        @current_user,
        @record,
        policy_class: Users::ApplicationPolicy,
        grant_signin_permission?: false,
      )

      assert users_applications_grant_access_link(@application, @grantee).empty?
    end
  end

  context "#account_applications_remove_access_link" do
    setup do
      @user = build(:user)
      stubs(:current_user).returns(@user)
      @application = create(:application)
    end

    should "generate a remove access link when the current user can remove the signin permission" do
      stub_policy @user, [:account, @application], remove_signin_permission?: true
      assert_includes account_applications_remove_access_link(@application), "Remove access"
    end

    should "return an empty string when the current user cannot remove the signin permission" do
      stub_policy @user, [:account, @application], remove_signin_permission?: false
      assert account_applications_remove_access_link(@application).empty?
    end
  end

  context "#users_applications_remove_access_link" do
    setup do
      @application = create(:application)
      @current_user = build(:user)
      stubs(:current_user).returns(@current_user)
      @grantee = create(:user)
      @record = { application: @application, user: @grantee }
    end

    should "generate a remove access link when the current user can remove the signin permission" do
      stub_policy(
        @current_user,
        @record,
        policy_class: Users::ApplicationPolicy,
        remove_signin_permission?: true,
      )

      assert_includes users_applications_remove_access_link(@application, @grantee), "Remove access"
    end

    should "return an empty string when the current user cannot remove the signin permission" do
      stub_policy(
        @current_user,
        @record,
        policy_class: Users::ApplicationPolicy,
        remove_signin_permission?: false,
      )
      assert users_applications_remove_access_link(@application, @grantee).empty?
    end
  end

  context "#account_applications_permissions_links" do
    setup do
      @user = build(:user)
      stubs(:current_user).returns(@user)
      @application = create(:application)
    end

    should "generate both view and update links when the user can both view and edit permissions" do
      stub_policy @user, [:account, @application], view_permissions?: true, edit_permissions?: true

      result = account_applications_permissions_links(@application)

      assert_includes result, "View permissions"
      assert_includes result, "Update permissions"
    end

    should "only generate a view link when the user can only view permissions" do
      stub_policy @user, [:account, @application], view_permissions?: true

      result = account_applications_permissions_links(@application)

      assert_includes result, "View permissions"
      assert_not_includes result, "Update permissions"
    end

    should "only generate an update link when the user can only edit permissions" do
      stub_policy @user, [:account, @application], edit_permissions?: true

      result = account_applications_permissions_links(@application)

      assert_not_includes result, "View permissions"
      assert_includes result, "Update permissions"
    end

    should "return an empty string when the user can do neither" do
      stub_policy @user, [:account, @application]
      assert account_applications_permissions_links(@application).empty?
    end
  end

  context "#users_applications_permissions_links" do
    setup do
      @application = create(:application)
      @current_user = build(:user)
      stubs(:current_user).returns(@current_user)
      @grantee = create(:user)
      @record = { application: @application, user: @grantee }
    end

    should "generate both view and update links when the user can both view and edit permissions" do
      stub_policy(
        @current_user,
        @record,
        policy_class: Users::ApplicationPolicy,
        edit_permissions?: true,
        view_permissions?: true,
      )

      result = users_applications_permissions_links(@application, @grantee)

      assert_includes result, "View permissions"
      assert_includes result, "Update permissions"
    end

    should "only generate a view link when the user can only view permissions" do
      stub_policy(
        @current_user,
        @record,
        policy_class: Users::ApplicationPolicy,
        edit_permissions?: false,
        view_permissions?: true,
      )

      result = users_applications_permissions_links(@application, @grantee)

      assert_includes result, "View permissions"
      assert_not_includes result, "Update permissions"
    end

    should "only generate an edit link when the user can only edit permissions" do
      stub_policy(
        @current_user,
        @record,
        policy_class: Users::ApplicationPolicy,
        edit_permissions?: true,
        view_permissions?: false,
      )

      result = users_applications_permissions_links(@application, @grantee)

      assert_not_includes result, "View permissions"
      assert_includes result, "Update permissions"
    end

    should "return an empty string when the user can do neither" do
      stub_policy(
        @current_user,
        @record,
        policy_class: Users::ApplicationPolicy,
        edit_permissions?: false,
        view_permissions?: false,
      )

      result = users_applications_permissions_links(@application, @grantee)

      assert_empty result
    end
  end

  context "#api_users_applications_permissions_link" do
    should "generate an update link when the user can edit permissions" do
      application = create(:application, with_non_delegatable_supported_permissions: %w[permission])
      granter = create(:superadmin_user)
      grantee = create(:api_user)
      stubs(:current_user).returns(granter)

      assert_includes api_users_applications_permissions_link(application, grantee), "Update permissions"
    end
  end

  context "#grant_access_link" do
    should "generate a link to grant access to the application" do
      application = create(:application)

      assert_includes grant_access_link(application), account_application_signin_permission_path(application)
    end

    context "when given a user" do
      should "generate a link to grant the user access to the application" do
        application = create(:application)
        user = create(:user)

        assert_includes grant_access_link(application, user), user_application_signin_permission_path(user, application)
      end
    end
  end

  context "#remove_access_link" do
    should "generate a link to remove access to the application" do
      application = create(:application)

      assert_includes remove_access_link(application), delete_account_application_signin_permission_path(application)
    end

    context "when provided with a user" do
      setup do
        @user = create(:user)
      end

      should "generate a link to remove users access to the application" do
        application = create(:application)

        assert_includes remove_access_link(application, @user), delete_user_application_signin_permission_path(@user, application)
      end
    end
  end

  context "#view_permissions_link" do
    should "generate a link to view the permissions" do
      application = create(:application, with_non_delegatable_supported_permissions: %w[permission])

      assert_includes view_permissions_link(application), account_application_permissions_path(application)
    end

    context "when provided with a user" do
      setup do
        @user = create(:user)
      end

      should "generate a link to view the permissions" do
        application = create(:application, with_non_delegatable_supported_permissions: %w[permission])

        assert_includes view_permissions_link(application, @user), user_application_permissions_path(@user, application)
      end
    end
  end

  context "#update_permissions_link" do
    setup do
      @application = create(:application)
      @current_user = create(:user)
      stubs(:current_user).returns(@current_user)
    end

    [
      { role_group: "GOV.UK admin", role_method: :govuk_admin?, app_method: :has_non_signin_permissions_grantable_from_ui? },
      { role_group: "publishing manager", role_method: :publishing_manager?, app_method: :has_delegatable_non_signin_permissions_grantable_from_ui? },
    ].each do |context_hash|
      context "when the current user is a #{context_hash[:role_group]}" do
        setup { @current_user.expects(context_hash[:role_method]).returns(true) }

        context "and there are permissions they can update" do
          setup { @application.expects(context_hash[:app_method]).returns(true) }

          context "when no user is provided" do
            should "generate a link to edit own permissions" do
              assert_includes update_permissions_link(@application), edit_account_application_permissions_path(@application)
            end
          end

          context "with a given normal user" do
            should "generate a link to edit the user's permissions" do
              user = create(:user)

              assert_includes update_permissions_link(@application, user), edit_user_application_permissions_path(user, @application)
            end
          end

          context "with a given API user" do
            should "generate a link to edit the API user's permissions" do
              user = create(:api_user)

              assert_includes update_permissions_link(@application, user), edit_api_user_application_permissions_path(user, @application)
            end
          end
        end

        context "and there are no permissions they can update" do
          should "return an empty string" do
            @application.expects(context_hash[:app_method]).returns(false)

            assert_empty update_permissions_link(@application)
          end
        end
      end
    end
  end
end
