require "test_helper"

class UsersHelperTest < ActionView::TestCase
  test "sync_needed? should work with user permissions not synced yet" do
    application = create(:application)
    user = create(:user)
    user.grant_application_signin_permission(application)

    assert_nothing_raised { sync_needed?(user.application_permissions) }
  end

  test "status should humanize User#status" do
    assert_equal "Invited", status(build(:invited_user))
    assert_equal "Active", status(build(:active_user))
    assert_equal "Locked", status(build(:locked_user))
    assert_equal "Suspended", status(build(:suspended_user))
  end

  test "two_step_status should reflect the user's status accurately when the user is exempted from 2sv" do
    assert_equal "Exempted", two_step_status(create(:two_step_exempted_user))
    assert_equal "Exempted", two_step_status_with_requirement(create(:two_step_exempted_user))
  end

  test "two_step_status should reflect the user's status accurately when the user has 2sv set up" do
    assert_equal "Enabled", two_step_status(create(:two_step_enabled_user))
    assert_equal "Enabled", two_step_status_with_requirement(create(:two_step_enabled_user))
  end

  test "two_step_status should reflect the user's status accurately when the user does not have 2sv set up" do
    assert_equal "Not set up", two_step_status(create(:user))
    assert_equal "Not set up", two_step_status_with_requirement(create(:user))
    assert_equal "Required but not set up", two_step_status_with_requirement(create(:two_step_mandated_user))
  end

  context "#filtered_users_heading" do
    setup do
      @users = [build(:user), build(:user)]
      @current_user = build(:user)
      stubs(:formatted_number_of_users).with(@users).returns("2 users")
      stubs(:current_user).returns(@current_user)
      @organisation = build(:organisation)
    end

    should "return formatted number of users" do
      another_organisation = build(:organisation)
      @current_user.stubs(:manageable_organisations).returns([@organisation, another_organisation])

      assert_equal "2 users", filtered_users_heading(@users)
    end

    should "return formatted number of users in specified organisation" do
      @current_user.stubs(:manageable_organisations).returns([@organisation])

      assert_equal "2 users in #{@organisation.name}", filtered_users_heading(@users)
    end
  end

  context "#options_for_role_select" do
    should "return role options suitable for select component" do
      roles = [Roles::Admin.role_name, Roles::Normal.role_name]
      stubs(:assignable_user_roles).returns(roles)

      options = options_for_role_select(selected: Roles::Normal.role_name)

      expected_options = [{ text: "Admin", value: "admin" }, { text: "Normal", value: "normal", selected: true }]
      assert_equal expected_options, options
    end
  end

  context "#options_for_organisation_select" do
    should "return organisation options suitable for select component, sorted alphabetically and exluding closed organisations" do
      user = create(:admin_user)
      stubs(:current_user).returns(user)

      organisation1 = create(:organisation, name: "B Organisation")
      organisation2 = create(:organisation, name: "A Organisation")
      create(:organisation, name: "Closed Organisation", closed: true)

      options = options_for_organisation_select(selected: organisation2.id)

      expected_options = [
        { text: "None", value: nil },
        { text: "A Organisation", value: organisation2.id, selected: true },
        { text: "B Organisation", value: organisation1.id },
      ]
      assert_equal expected_options, options
    end
  end

  context "#options_for_permission_option_select" do
    should "return permission options suitable for option-select component" do
      application = create(:application)
      signin_permission = application.signin_permission
      permission1 = create(:supported_permission, application:, name: "permission1")
      permission2 = create(:supported_permission, application:, name: "permission2")

      user = create(:user, supported_permissions: [signin_permission, permission1])

      options = options_for_permission_option_select(application:, user:)

      expected_options = [
        {
          label: "Has access to #{application.name}?",
          value: signin_permission.id,
          checked: true,
        },
        {
          label: "permission1",
          value: permission1.id,
          checked: true,
        },
        {
          label: "permission2",
          value: permission2.id,
          checked: false,
        },
      ]

      assert_equal expected_options, options
    end
  end

  context "#formatted_permission_name" do
    should "return the permission name if permission is not the signin permission" do
      assert_equal "Editor", formatted_permission_name("Whitehall", "Editor")
    end

    should "include the application name if permission is the signin permission" do
      assert_equal "Has access to Whitehall?", formatted_permission_name("Whitehall", SupportedPermission::SIGNIN_NAME)
    end
  end

  context "#link_to_access_log" do
    should "returns link to access log for user" do
      user = build(:user, id: 123)
      html = link_to_access_log(user)
      node = Nokogiri::HTML5.fragment(html)
      assert_select node, "a[href='#{event_logs_user_path(user)}']", text: "Account access log"
    end
  end

  context "#link_to_suspension" do
    context "when current user has permission to suspend a user" do
      setup do
        stubs(:policy).returns(stub("policy", suspension?: true))
      end

      should "returns link to suspend user for non-suspended user" do
        user = build(:user, id: 123)
        html = link_to_suspension(user)
        node = Nokogiri::HTML5.fragment(html)
        assert_select node, "a[href='#{edit_suspension_path(user)}']", text: "Suspend user"
      end

      should "returns link to unsuspend user for suspended user" do
        user = build(:suspended_user, id: 123)
        html = link_to_suspension(user)
        node = Nokogiri::HTML5.fragment(html)
        assert_select node, "a[href='#{edit_suspension_path(user)}']", text: "Unsuspend user"
      end
    end

    context "when current user does not have permission to suspend a user" do
      setup do
        stubs(:policy).returns(stub("policy", suspension?: false))
      end

      should "returns nil" do
        user = build(:user, id: 123)
        assert_nil link_to_suspension(user)
      end
    end
  end

  context "#link_to_resend_invitation" do
    context "when current user has permission to resend signup email to a user" do
      setup do
        stubs(:policy).returns(stub("policy", resend_invitation?: true))
      end

      should "returns link to resend signup email to user for invited user" do
        user = build(:invited_user, id: 123)
        html = link_to_resend_invitation(user)
        node = Nokogiri::HTML5.fragment(html)
        assert_select node, "a[href='#{edit_user_invitation_resend_path(user)}']", text: "Resend signup email"
      end

      should "returns nil for user who has accepted invitation" do
        user = build(:active_user, id: 123)
        assert_nil link_to_resend_invitation(user)
      end
    end

    context "when current user does not have permission to resend signup email to a user" do
      setup do
        stubs(:policy).returns(stub("policy", resend_invitation?: false))
      end

      should "returns nil" do
        user = build(:invited_user, id: 123)
        assert_nil link_to_resend_invitation(user)
      end
    end
  end

  context "#link_to_unlock" do
    context "when current user has permission to unlock a user" do
      setup do
        stubs(:policy).returns(stub("policy", unlock?: true))
      end

      should "returns link to unlock user for locked user" do
        user = build(:locked_user, id: 123)
        html = link_to_unlock(user)
        node = Nokogiri::HTML5.fragment(html)
        assert_select node, "a[href='#{edit_user_unlocking_path(user)}']", text: "Unlock account"
      end

      should "returns nil for user who is not locked" do
        user = build(:user, id: 123)
        assert_nil link_to_unlock(user)
      end
    end

    context "when current user does not have permission to unlock a user" do
      setup do
        stubs(:policy).returns(stub("policy", unlock?: false))
      end

      should "returns nil" do
        user = build(:locked_user, id: 123)
        assert_nil link_to_unlock(user)
      end
    end
  end

  context "#link_to_2sv_exemption" do
    context "when current user has permission to exempt a user from 2SV" do
      setup do
        stubs(:policy).returns(stub("policy", exempt_from_two_step_verification?: true))
      end

      should "returns link to create 2SV exemption for user who does not have exemption" do
        user = build(:user, id: 123)
        html = link_to_2sv_exemption(user)
        node = Nokogiri::HTML5.fragment(html)
        expected_link_text = "Exempt user from 2-step verification"
        assert_select node, "a[href='#{edit_two_step_verification_exemption_path(user)}']", text: expected_link_text
      end

      should "returns link to update 2SV exemption for user who has exemption" do
        user = build(:two_step_exempted_user, id: 123)
        html = link_to_2sv_exemption(user)
        node = Nokogiri::HTML5.fragment(html)
        expected_link_text = "Edit reason or expiry date for 2-step verification exemption"
        assert_select node, "a[href='#{edit_two_step_verification_exemption_path(user)}']", text: expected_link_text
      end
    end

    context "when current user does not have permission to exempt a user from 2SV" do
      setup do
        stubs(:policy).returns(stub("policy", exempt_from_two_step_verification?: false))
      end

      should "returns nil" do
        user = build(:user, id: 123)
        assert_nil link_to_2sv_exemption(user)
      end
    end
  end
end
