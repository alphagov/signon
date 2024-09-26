require "test_helper"

class UpdatingPermissionsForAppsWithManyPermissionsTest < ActionDispatch::IntegrationTest
  # Also see: Account::UpdatingPermissionsTest, Users::UpdatingPermissionsTest

  autocomplete_helper = AutocompleteHelper.new

  def navigate_to_update_my_own_permissions_page
    visit new_user_session_path
    signin_with @current_user

    visit account_applications_path
    click_link "Update permissions for #{@application.name}"
  end

  def navigate_to_update_other_user_permissions_page
    visit new_user_session_path
    signin_with @current_user

    visit user_applications_path(@grantee)
    click_link "Update permissions for #{@application.name}"
  end

  def navigate_to_update_permissions_page
    @updating_own_permissions ? navigate_to_update_my_own_permissions_page : navigate_to_update_other_user_permissions_page
  end

  [
    { description: "updating my own permissions", updating_own_permissions: true },
    { description: "updating someone else's permissions", updating_own_permissions: false },
  ].each do |context_hash|
    context context_hash[:description] do
      setup do
        @updating_own_permissions = context_hash[:updating_own_permissions]
      end

      context "updating permissions" do
        setup do
          @application = create(:application)
          create_list(:supported_permission, 8, application: @application)

          @current_user = create(:superadmin_user)
          @grantee = @updating_own_permissions ? @current_user : create(:user)

          @grantee.grant_application_signin_permission(@application)

          @existing_permission = create(:supported_permission, application: @application)
          @grantee.grant_application_permissions(@application, [@existing_permission.name])
          @new_permission_to_grant = create(:supported_permission, application: @application)
        end

        context "when JS is enabled" do
          setup do
            use_javascript_driver
            navigate_to_update_permissions_page
          end

          should "I should be able to grant myself some permissions from the autocomplete" do
            autocomplete_helper.select_autocomplete_option(@new_permission_to_grant.name)
            click_button "Add and finish"

            assert @grantee.has_permission?(@new_permission_to_grant)
            assert_flash_content([@new_permission_to_grant.name, @existing_permission.name])
            assert @grantee.has_permission?(@existing_permission)
          end

          should "be able to add multiple permissions one after the other when clicking 'add'" do
            newer_permission_to_grant = create(:supported_permission, application: @application)

            autocomplete_helper.select_autocomplete_option(@new_permission_to_grant.name)
            click_button "Add"

            assert @grantee.has_permission?(@new_permission_to_grant)
            assert_flash_content("You have successfully added the permission '#{@new_permission_to_grant.name}'.")

            autocomplete_helper.select_autocomplete_option(newer_permission_to_grant.name)
            click_button "Add"

            assert @grantee.has_permission?(newer_permission_to_grant)
            assert_flash_content("You have successfully added the permission '#{newer_permission_to_grant.name}'.")
          end
        end

        context "when JS is disabled" do
          setup do
            navigate_to_update_permissions_page
          end

          should "be able to grant myself some permissions from the select element" do
            select @new_permission_to_grant.name
            click_button "Add and finish"
            assert @grantee.has_permission?(@new_permission_to_grant)
            assert @grantee.has_permission?(@existing_permission)
          end
        end

        should "should be able to remove permissions by unchecking them" do
          navigate_to_update_permissions_page

          uncheck @existing_permission.name
          click_button "Update permissions"

          assert_not @grantee.has_permission?(@existing_permission)
        end
      end

      context "displaying different forms based on the number of the user's permissions" do
        setup do
          @current_user = create(:superadmin_user)
          @grantee = @updating_own_permissions ? @current_user : create(:user)
          @application = create(:application)
          @supported_permissions = create_list(:supported_permission, 9, application: @application)
        end

        context "when the grantee already has the signin permission but not all other permissions" do
          setup do
            @grantee.grant_application_signin_permission(@application)
            @grantee.grant_application_permissions(@application, @supported_permissions.first(3).map(&:name))
            navigate_to_update_permissions_page
          end

          should "display the new and current permissions forms" do
            assert assert_selector ".govuk-label", text: "Add a permission"
            assert assert_selector "legend", text: "Current permissions"
          end
        end

        context "when I have all permissions, including signin" do
          setup do
            @grantee.grant_application_permissions(@application, @application.supported_permissions.map(&:name))
            navigate_to_update_permissions_page
          end

          should "only display the current permissions form" do
            assert assert_no_selector ".govuk-label", text: "Add a permission"
            assert assert_selector "legend", text: "Current permissions"
          end
        end

        context "when I only have the signin permission" do
          setup do
            @grantee.grant_application_signin_permission(@application)
            navigate_to_update_permissions_page
          end

          should "only display the new permissions form" do
            assert assert_selector ".govuk-label", text: "Add a permission"
            assert assert_no_selector "legend", text: "Current permissions"
          end
        end
      end
    end
  end
end
