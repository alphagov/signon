require "test_helper"

class Users::UnlockingsControllerTest < ActionController::TestCase
  context "GET edit" do
    context "signed in as Admin user" do
      setup do
        @admin = create(:admin_user)
        sign_in(@admin)
      end

      should "display form with submit button & cancel link" do
        user = create(:locked_user)

        get :edit, params: { user_id: user }

        assert_template :edit
        assert_select "form[action='#{user_unlocking_path(user)}']" do
          assert_select "button[type='submit']", text: "Unlock account"
          assert_select "a[href='#{edit_user_path(user)}']", text: "Cancel"
        end
      end

      should "authorize access if UserPolicy#unlock? returns true" do
        user = create(:locked_user)

        user_policy = stub_everything("user-policy", unlock?: true)
        UserPolicy.stubs(:new).returns(user_policy)

        get :edit, params: { user_id: user }

        assert_template :edit
      end

      should "not authorize access if UserPolicy#unlock? returns false" do
        user = create(:locked_user)

        user_policy = stub_everything("user-policy", unlock?: false)
        UserPolicy.stubs(:new).returns(user_policy)

        get :edit, params: { user_id: user }

        assert_not_authorised
      end

      should "redirect to edit user page if user is already unlocked" do
        user = create(:active_user, email: "user@gov.uk")

        get :edit, params: { user_id: user }

        assert_equal "user@gov.uk is already unlocked", flash[:notice]
        assert_redirected_to edit_user_path(user)
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

        assert_not_authenticated
      end
    end
  end

  context "PUT update" do
    context "signed in as Admin user" do
      setup do
        @admin = create(:admin_user)
        sign_in(@admin)
      end

      should "unlock user" do
        user = create(:locked_user)

        put :update, params: { user_id: user }

        assert_not user.reload.access_locked?
      end

      should "record manual account unlock event" do
        user = create(:locked_user)

        @controller.stubs(:user_ip_address).returns("1.1.1.1")

        EventLog.expects(:record_event).with(
          user,
          EventLog::MANUAL_ACCOUNT_UNLOCK,
          initiator: @admin,
          ip_address: "1.1.1.1",
        )

        put :update, params: { user_id: user }
      end

      should "not record manual account unlock event if User#unlock! raises an exception" do
        user = build(:locked_user, id: 123)
        User.stubs(:find).returns(user)
        user.stubs(:unlock_access!).raises("boom!")

        EventLog.expects(:record_event).never

        assert_raises { put :update, params: { user_id: user } }
      end

      should "redirect to edit user page and display success notice" do
        user = create(:locked_user, email: "user@gov.uk")

        put :update, params: { user_id: user }

        assert_redirected_to edit_user_path(user)
        assert_equal "Unlocked user@gov.uk", flash[:notice]
      end

      should "unlock user if UserPolicy#unlock? returns true" do
        user = create(:locked_user)

        user_policy = stub_everything("user-policy", unlock?: true)
        UserPolicy.stubs(:new).returns(user_policy)

        put :update, params: { user_id: user }

        assert_not user.reload.access_locked?
      end

      should "not unock user if UserPolicy#unlock? returns false" do
        user = create(:locked_user)

        user_policy = stub_everything("user-policy", unlock?: false)
        UserPolicy.stubs(:new).returns(user_policy)

        put :update, params: { user_id: user }

        assert user.reload.access_locked?
      end

      should "redirect to edit user page if user is already unlocked" do
        user = create(:active_user, email: "user@gov.uk")

        get :update, params: { user_id: user }

        assert_equal "user@gov.uk is already unlocked", flash[:notice]
        assert_redirected_to edit_user_path(user)
      end
    end

    context "signed in as Normal user" do
      setup do
        sign_in(create(:user))
      end

      should "not be authorized" do
        user = create(:locked_user)

        put :update, params: { user_id: user }

        assert_not_authorised
      end
    end

    context "not signed in" do
      should "not be allowed access" do
        user = create(:locked_user)

        put :update, params: { user_id: user }

        assert_not_authenticated
      end
    end
  end
end
