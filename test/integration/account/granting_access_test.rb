require "test_helper"

class Account::GrantingAccessTest < ActionDispatch::IntegrationTest
  setup { @application = create(:application) }

  %w[superadmin admin].each do |admin_role|
    context "as a #{admin_role}" do
      setup do
        @user = create(:"#{admin_role}_user")
        visit new_user_session_path
        signin_with @user
      end

      should "be able to grant themselves access to an application" do
        visit account_applications_path
        click_button "Grant access to #{@application.name}"

        app_with_access_table = find("table caption[text()='Apps you have access to']").ancestor("table")

        assert app_with_access_table.has_content?(@application.name)
        assert @user.has_access_to?(@application)
      end
    end
  end

  %w[super_organisation_admin organisation_admin].each do |publishing_manager_role|
    context "as a #{publishing_manager_role}" do
      setup do
        @user = create(:"#{publishing_manager_role}_user")
        visit new_user_session_path
        signin_with @user
      end

      should "not be able to grant themselves access to application" do
        visit account_applications_path
        assert page.has_content?("GOV.UK apps")

        assert_not page.has_link?("Grant access to #{@application.name}")
      end
    end
  end
end
