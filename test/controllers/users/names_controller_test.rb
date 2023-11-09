require "test_helper"

class Users::NamesControllerTest < ActionController::TestCase
  context "GET edit" do
    context "signed in as Admin user" do
      setup do
        sign_in(create(:admin_user))
      end

      should "display form with name field" do
        user = create(:user, name: "user-name")

        get :edit, params: { user_id: user }

        assert_template :edit
        assert_select "form[action='#{user_name_path(user)}']" do
          assert_select "input[name='user[name]']", value: "user-name"
        end
      end

      should "authorize access if UserPolicy#edit? returns true" do
        user = create(:user)

        user_policy = stub_everything("user-policy", edit?: true)
        UserPolicy.stubs(:new).returns(user_policy)

        get :edit, params: { user_id: user }

        assert_template :edit
      end

      should "not authorize access if UserPolicy#edit? returns false" do
        user = create(:user)

        user_policy = stub_everything("user-policy", edit?: false)
        UserPolicy.stubs(:new).returns(user_policy)

        get :edit, params: { user_id: user }

        assert_not_authorised
      end
    end

    context "signed in as Normal user" do
      setup do
        sign_in(create(:user))
      end

      should "not be authorized" do
        user = create(:user)

        get :edit, params: { user_id: user }

        assert_not_authorised
      end
    end

    context "not signed in" do
      should "not be allowed access" do
        user = create(:user)

        get :edit, params: { user_id: user }

        assert_redirected_to new_user_session_path
      end
    end
  end

  context "PUT update" do
    context "signed in as Admin user" do
      setup do
        @admin = create(:admin_user)
        sign_in(@admin)
      end

      should "update user name" do
        user = create(:user, name: "user-name")

        put :update, params: { user_id: user, user: { name: "new-user-name" } }

        assert_equal "new-user-name", user.reload.name
      end

      should "record account updated event" do
        user = create(:user)

        @controller.stubs(:user_ip_address).returns("1.1.1.1")

        EventLog.expects(:record_event).with(
          user,
          EventLog::ACCOUNT_UPDATED,
          initiator: @admin,
          ip_address: "1.1.1.1",
        )

        put :update, params: { user_id: user, user: { name: "new-user-name" } }
      end

      should "redirect to user page and display success notice" do
        user = create(:user, email: "user@gov.uk")

        put :update, params: { user_id: user, user: { name: "new-user-name" } }

        assert_redirected_to edit_user_path(user), notice: "Updated name of user@gov.uk successfully"
      end

      should "update user name if UserPolicy#update? returns true" do
        user = create(:user, name: "user-name")

        user_policy = stub_everything("user-policy", update?: true)
        UserPolicy.stubs(:new).returns(user_policy)

        put :update, params: { user_id: user, user: { name: "new-user-name" } }

        assert_equal "new-user-name", user.reload.name
      end

      should "not update user name if UserPolicy#update? returns false" do
        user = create(:user, name: "user-name")

        user_policy = stub_everything("user-policy", update?: false)
        UserPolicy.stubs(:new).returns(user_policy)

        put :update, params: { user_id: user, user: { name: "new-user-name" } }

        assert_equal "user-name", user.reload.name
        assert_not_authorised
      end

      should "redisplay form if name is not valid" do
        user = create(:user, name: "user-name")

        put :update, params: { user_id: user, user: { name: "" } }

        assert_template :edit
        assert_select "form[action='#{user_name_path(user)}']" do
          assert_select "input[name='user[name]']", value: ""
        end
      end

      should "use original name in page title, heading & breadcrumbs if new name was not valid" do
        user = create(:user, name: "user-name")

        put :update, params: { user_id: user, user: { name: "" } }

        assert_select "head title", text: /^Change name for user-name/
        assert_select "h1", text: "Change name for user-name"
        assert_select ".govuk-breadcrumbs li", text: "user-name"
      end

      should "display errors if name is not valid" do
        user = create(:user)

        put :update, params: { user_id: user, user: { name: "" } }

        assert_select ".govuk-error-summary" do
          assert_select "a", href: "#user_name", text: "Name can't be blank"
        end
        assert_select ".govuk-form-group" do
          assert_select ".govuk-error-message", text: "Error: Name can't be blank"
          assert_select "input[name='user[name]'].govuk-input--error"
        end
      end
    end

    context "signed in as Normal user" do
      setup do
        sign_in(create(:user))
      end

      should "update user name" do
        user = create(:user, name: "user-name")

        put :update, params: { user_id: user, user: { name: "new-user-name" } }

        assert_not_authorised
      end
    end

    context "not signed in" do
      should "not be allowed access" do
        user = create(:user)

        get :edit, params: { user_id: user }

        assert_redirected_to new_user_session_path
      end
    end
  end
end
