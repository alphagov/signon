require "test_helper"

class UpdatingPermissionsForAppsWithManyPermissionsTest < ActionDispatch::IntegrationTest
  # Also see: Account::UpdatingPermissionsTest, Users::UpdatingPermissionsTest

  def shared_setup
    @grantee_is_self = rand(2).zero?

    @application = create(:application)
    @old_permissions_to_keep = create_list(:supported_permission, 3, application: @application)
    @old_permission_to_remove_without_javascript = create(:supported_permission, application: @application)
    @new_permissions_to_leave = create_list(:supported_permission, 4, application: @application)
    @new_permission_to_grant = create(:supported_permission, application: @application, name: "adding")

    @current_user = create(:superadmin_user)
    @grantee = @grantee_is_self ? @current_user : create(:user)
    @grantee.grant_application_signin_permission(@application)
    @grantee.grant_application_permissions(@application, [*@old_permissions_to_keep, @old_permission_to_remove_without_javascript].map(&:name))

    visit new_user_session_path
    signin_with @current_user
  end

  def assert_select_permission_to_grant_with_javascript
    @grantee_is_self ? assert_edit_self : assert_edit_other_user(@grantee)

    click_link "Update permissions for #{@application.name}"

    @autocomplete_input = find(".autocomplete__input")
    @select_element = find("#new_permission_id-select", visible: false)
    assert_equal "", @autocomplete_input.value
    assert_equal "", @select_element.value

    # when I type a few characters from a permission called "adding"
    @autocomplete_input.fill_in with: "add"
    autocomplete_option = find(".autocomplete__option")

    # the autcomplete value reflects what I typed, a matching option appears, but the select element remains empty
    assert_equal "add", @autocomplete_input.value
    assert_equal @new_permission_to_grant.name, autocomplete_option.text
    assert_equal "", @select_element.value

    # when I click on the matching option
    autocomplete_option.click

    # the autocomplete and select elements reflect my selection
    assert_equal @new_permission_to_grant.name, @autocomplete_input.value
    assert_equal @new_permission_to_grant.id.to_s, @select_element.value
  end

  context "with apps that have more than eight permissions" do
    context "with JavaScript disabled" do
      setup { shared_setup }

      should "be able to grant permissions" do
        @grantee_is_self ? assert_edit_self : assert_edit_other_user(@grantee)

        click_link "Update permissions for #{@application.name}"
        select @new_permission_to_grant.name
        click_button "Add and finish"

        click_link "Update permissions for #{@application.name}"
        uncheck @old_permission_to_remove_without_javascript.name
        click_button "Update permissions"

        expected_permissions = [*@old_permissions_to_keep, @new_permission_to_grant]
        assert_flash_content(expected_permissions.map(&:name))
        expected_permissions.each { |expected_permission| assert @grantee.has_permission?(expected_permission) }

        unexpected_permissions = [@old_permission_to_remove_without_javascript, *@new_permissions_to_leave]
        refute_flash_content(unexpected_permissions.map(&:name))
        unexpected_permissions.each { |unexpected_permission| assert_not @grantee.has_permission?(unexpected_permission) }
      end

      context "when the grantee already has some but not all permissions" do
        should "display the new and current permissions forms" do
          @grantee_is_self ? assert_edit_self : assert_edit_other_user(@grantee)

          click_link "Update permissions for #{@application.name}"

          assert_selector ".govuk-label", text: "Add a permission"
          assert_selector "legend", text: "Current permissions"
        end
      end

      context "when the grantee has all permissions" do
        setup do
          @grantee.grant_application_permissions(@application, [*@new_permissions_to_leave, @new_permission_to_grant].map(&:name))
        end

        should "only display the current permissions form" do
          @grantee_is_self ? assert_edit_self : assert_edit_other_user(@grantee)

          click_link "Update permissions for #{@application.name}"

          assert_no_selector ".govuk-label", text: "Add a permission"
          assert_selector "legend", text: "Current permissions"
        end
      end

      context "when the grantee has no permissions" do
        setup do
          old_permission_ids = [*@old_permissions_to_keep, @old_permission_to_remove_without_javascript].pluck(:id)
          UserApplicationPermission.where(user: @grantee, supported_permission_id: old_permission_ids).destroy_all
        end

        should "only display the new permissions form" do
          @grantee_is_self ? assert_edit_self : assert_edit_other_user(@grantee)

          click_link "Update permissions for #{@application.name}"

          assert_selector ".govuk-label", text: "Add a permission"
          assert_no_selector "legend", text: "Current permissions"
        end
      end
    end

    context "with JavaScript enabled" do
      setup do
        use_javascript_driver
        shared_setup
      end

      should "be able to grant permissions" do
        assert_select_permission_to_grant_with_javascript

        click_button "Add and finish"

        expected_permissions = [*@old_permissions_to_keep, @new_permission_to_grant, @old_permission_to_remove_without_javascript]
        assert_flash_content(expected_permissions.map(&:name))
        expected_permissions.each { |expected_permission| assert @grantee.has_permission?(expected_permission) }

        unexpected_permissions = @new_permissions_to_leave
        refute_flash_content(unexpected_permissions.map(&:name))
        unexpected_permissions.each { |unexpected_permission| assert_not @grantee.has_permission?(unexpected_permission) }
      end

      should "grant permissions then redirect back to the form when clicking 'Add'" do
        assert_select_permission_to_grant_with_javascript

        click_button "Add"

        expected_permissions = [*@old_permissions_to_keep, @new_permission_to_grant, @old_permission_to_remove_without_javascript]
        expected_permissions.each { |expected_permission| assert @grantee.has_permission?(expected_permission) }

        unexpected_permissions = @new_permissions_to_leave
        unexpected_permissions.each { |unexpected_permission| assert_not @grantee.has_permission?(unexpected_permission) }

        h1_content = @grantee_is_self ? "Update permissions for #{@application.name}" : "Update #{@grantee.name}'s permissions for #{@application.name}"
        assert page.has_selector?("h1", text: h1_content)
        assert_flash_content("You have successfully added the permission '#{@new_permission_to_grant.name}'.")
      end
    end
  end
end
