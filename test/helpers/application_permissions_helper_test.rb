require "test_helper"

class ApplicationPermissionsHelperTest < ActionView::TestCase
  context "#permissions_updated_description" do
    setup do
      @application = create(:application, name: "Whitehall", with_non_delegatable_supported_permissions: ["Permission 1"])
      user = create(:user, with_permissions: { @application => ["Permission 1", SupportedPermission::SIGNIN_NAME] })
      stubs(:current_user).returns(user)
    end

    should "include the application name in the message" do
      assert_includes permissions_updated_description(@application.id), "You now have the following permissions for Whitehall"
    end

    should "include the users permissions in the message" do
      assert_includes permissions_updated_description(@application.id), "Permission 1"
    end

    should "not include the signin permission in the message" do
      assert_not_includes permissions_updated_description(@application.id), "signin"
    end

    context "when the application does not exist" do
      should "return nil" do
        assert_nil permissions_updated_description(:made_up_id)
      end
    end

    context "when the user has no additional permissions" do
      setup do
        user = create(:user, with_permissions: { @application => [SupportedPermission::SIGNIN_NAME] })
        stubs(:current_user).returns(user)
      end

      should "indicate that the user has no additional permissions" do
        assert_includes permissions_updated_description(@application.id), "You can access Whitehall but you do not have any additional permissions."
      end
    end

    context "when the user isn't the current user" do
      setup do
        @user = create(:user, name: "user-name", with_permissions: { @application => ["Permission 1", SupportedPermission::SIGNIN_NAME] })
      end

      should "include the application name in the message" do
        assert_includes permissions_updated_description(@application.id, @user), "user-name now has the following permissions for Whitehall"
      end
    end

    context "when the user isn't the current user and the user has no additional permissions" do
      setup do
        @user = create(:user, name: "user-name", with_permissions: { @application => [SupportedPermission::SIGNIN_NAME] })
      end

      should "indicate that the user has no additional permissions" do
        assert_includes permissions_updated_description(@application.id, @user), "user-name can access Whitehall but does not have any additional permissions."
      end
    end
  end

  context "#notice_about_non_delegatable_permissions" do
    context "when the current user is a GOV.UK admin" do
      setup do
        @current_user = create(:user)
        @current_user.expects(:govuk_admin?).returns(true)
      end

      should "return nil" do
        assert_nil notice_about_non_delegatable_permissions(@current_user, create(:application))
      end
    end

    context "when the current user is not a GOV.UK admin" do
      setup do
        @current_user = create(:user, name: "Current User")
        @current_user.expects(:govuk_admin?).returns(false)
        @application = create(:application, name: "My First App")
      end

      context "when the app has no non-delegatable non-signin permissions grantable from the UI" do
        setup { @application.expects(:has_non_delegatable_non_signin_permissions_grantable_from_ui?).returns(false) }

        should "return nil" do
          assert_nil notice_about_non_delegatable_permissions(@current_user, @application)
        end
      end

      context "when the app has some non-delegatable non-signin permissions grantable from the UI" do
        setup { @application.expects(:has_non_delegatable_non_signin_permissions_grantable_from_ui?).returns(true) }

        context "without another user passed in as the grantee" do
          should "infer the grantee as the current user and return a notice with a link to the account application permissions path" do
            link = "<a class=\"govuk-link\" href=\"#{account_application_permissions_path(@application)}\">view all the permissions you have for My First App</a>"

            assert_equal(
              "Below, you will only see permissions that you are authorised to manage. You can also #{link}.",
              notice_about_non_delegatable_permissions(@current_user, @application),
            )
          end
        end

        context "with another user passed in as the grantee" do
          should "return a notice with a link to the user application permissions path for the given grantee" do
            grantee = create(:user, name: "Another User")

            link = "<a class=\"govuk-link\" href=\"#{user_application_permissions_path(grantee, @application)}\">view all the permissions Another User has for My First App</a>"

            assert_equal(
              "Below, you will only see permissions that you are authorised to manage. You can also #{link}.",
              notice_about_non_delegatable_permissions(@current_user, @application, grantee),
            )
          end
        end
      end
    end
  end
end
