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

  context "#summary_list_item_for_name" do
    context "when user is non-API user" do
      should "return item options with edit link to change name" do
        user = build(:user, id: 123, name: "user-name")
        item = summary_list_item_for_name(user)
        assert_equal item[:field], "Name"
        assert_equal item[:value], "user-name"
        assert_equal item.dig(:edit, :href), edit_user_name_path(user)
      end
    end

    context "when user is API user" do
      should "return item options with edit link to change name" do
        user = build(:api_user, id: 123, name: "user-name")
        item = summary_list_item_for_name(user)
        assert_equal item[:field], "Name"
        assert_equal item[:value], "user-name"
        assert_equal item.dig(:edit, :href), edit_api_user_name_path(user)
      end
    end
  end

  context "#summary_list_item_for_email" do
    should "return item options with edit link to change email" do
      user = build(:user, id: 123, email: "user@gov.uk")
      item = summary_list_item_for_email(user)
      assert_equal item[:field], "Email"
      assert_equal item[:value], "user@gov.uk"
      assert_equal item.dig(:edit, :href), edit_user_email_path(user)
    end
  end

  context "#summary_list_item_for_organisation" do
    context "when current user has permission to assign organisation" do
      setup do
        stubs(:policy).returns(stub("policy", assign_organisation?: true))
      end

      should "return item options with edit link to change organisation" do
        organisation = build(:organisation, name: "organisation-name")
        user = build(:user, id: 123, organisation:)
        item = summary_list_item_for_organisation(user)
        assert_equal item[:field], "Organisation"
        assert_equal item[:value], "organisation-name"
        assert_equal item.dig(:edit, :href), edit_user_organisation_path(user)
      end
    end

    context "when current user does not have permission to assign organisation" do
      setup do
        stubs(:policy).returns(stub("policy", assign_organisation?: false))
      end

      should "return item options without edit link" do
        organisation = build(:organisation, name: "organisation-name")
        user = build(:user, id: 123, organisation:)
        item = summary_list_item_for_organisation(user)
        assert_nil item[:edit]
      end
    end
  end

  context "#summary_list_item_for_role" do
    context "when current user has permission to assign role" do
      setup do
        stubs(:policy).returns(stub("policy", assign_role?: true))
      end

      should "return item options with edit link to change role" do
        user = build(:admin_user, id: 123)
        item = summary_list_item_for_role(user)
        assert_equal item[:field], "Role"
        assert_equal item[:value], "Admin"
        assert_equal item.dig(:edit, :href), edit_user_role_path(user)
      end
    end

    context "when current user does not have permission to assign role" do
      setup do
        stubs(:policy).returns(stub("policy", assign_role?: false))
      end

      should "return item options without edit link" do
        user = build(:admin_user, id: 123)
        item = summary_list_item_for_role(user)
        assert_nil item[:edit]
      end
    end
  end

  context "#summary_list_item_for_status" do
    should "return item options without edit link" do
      user = build(:active_user, id: 123)
      item = summary_list_item_for_status(user)
      assert_equal item[:field], "Status"
      assert_equal item[:value], "Active"
      assert_nil item[:edit]
    end
  end

  context "#summary_list_item_for_2sv_status" do
    should "return item options without edit link" do
      user = build(:two_step_enabled_user, id: 123)
      item = summary_list_item_for_2sv_status(user)
      assert_equal item[:field], "2-step verification"
      assert_equal item[:value], "Enabled"
      assert_nil item[:edit]
    end
  end

  context "#link_to_access_log" do
    should "returns link to access log for user" do
      user = build(:user, id: 123)
      html = link_to_access_log(user)
      node = Nokogiri::HTML5.fragment(html)
      assert_select node, "a[href='#{event_logs_user_path(user)}']", text: "View account access log"
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
        expected_link_text = "Edit 2-step verification exemption"
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

  context "#link_to_reset_2sv" do
    context "when current user has permission to reset 2SV for a user" do
      setup do
        stubs(:policy).returns(stub("policy", reset_2sv?: true))
      end

      should "returns link to reset 2SV for user who has 2SV setup" do
        user = build(:two_step_enabled_user, id: 123)
        html = link_to_reset_2sv(user)
        node = Nokogiri::HTML5.fragment(html)
        expected_link_text = "Reset 2-step verification"
        assert_select node, "a[href='#{edit_user_two_step_verification_reset_path(user)}']", text: expected_link_text
      end

      should "returns nil for user who does not have 2SV setup" do
        user = build(:user, id: 123)
        assert_nil link_to_reset_2sv(user)
      end
    end

    context "when current user does not have permission to reset 2SV for a user" do
      setup do
        stubs(:policy).returns(stub("policy", reset_2sv?: false))
      end

      should "returns nil" do
        user = build(:two_step_enabled_user, id: 123)
        assert_nil link_to_reset_2sv(user)
      end
    end
  end

  context "#link_to_mandate_2sv" do
    context "when current user has permission to mandate 2SV for a user" do
      setup do
        stubs(:policy).returns(stub("policy", mandate_2sv?: true))
      end

      should "returns link to mandate 2SV for user for whom 2SV is not required" do
        user = build(:user, id: 123)
        html = link_to_mandate_2sv(user)
        node = Nokogiri::HTML5.fragment(html)
        expected_link_text = "Turn on 2-step verification for this user"
        assert_select node, "a[href='#{edit_user_two_step_verification_mandation_path(user)}']", text: expected_link_text
      end

      should "returns nil for user for whom 2SV is required" do
        user = build(:two_step_mandated_user, id: 123)
        assert_nil link_to_mandate_2sv(user)
      end
    end

    context "when current user does not have permission to mandate 2SV for a user" do
      setup do
        stubs(:policy).returns(stub("policy", mandate_2sv?: false))
      end

      should "returns nil" do
        user = build(:user, id: 123)
        assert_nil link_to_mandate_2sv(user)
      end
    end
  end
end
