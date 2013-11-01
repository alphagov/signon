require 'test_helper'

class Admin::UsersControllerTest < ActionController::TestCase

  setup do
    @user = FactoryGirl.create(:user, role: "admin")
    sign_in @user
  end

  context "GET index" do
    should "list users" do
      FactoryGirl.create(:user, email: "another_user@email.com")
      get :index
      assert_select "td.email", /another_user@email.com/
    end

    should "let you paginate by the first letter of the name" do
      FactoryGirl.create(:user, name: "alf", email: "a@email.com")
      FactoryGirl.create(:user, name: "zed", email: "z@email.com")
      get :index, letter: "Z"
      assert_select "td.email", /z@email.com/
      assert_select "tbody tr", count: 1
    end

    context "filter" do
      should "filter results to users where their name or email contains the string" do
        FactoryGirl.create(:user, email: "a@another.gov.uk")
        FactoryGirl.create(:user, email: "a@dfid.gov.uk")
        get :index, filter: "dfid"
        assert_select "td.email", /a@dfid.gov.uk/
        assert_select "tbody tr", count: 1
      end
    end
  end

  context "GET edit" do
    should "show the form" do
      not_an_admin = FactoryGirl.create(:user)
      get :edit, id: not_an_admin.id
      assert_select "input[name='user[email]'][value='#{not_an_admin.email}']"
    end

    should "show the pending email if applicable" do
      another_user = FactoryGirl.create(:user_with_pending_email_change)
      get :edit, id: another_user.id
      assert_select "input[name='user[unconfirmed_email]'][value='#{another_user.unconfirmed_email}']"
    end

    context "when editing of user membership of organisations is enabled" do
      should "show the organisation to which the user belongs" do
        with_const_override(:DISABLE_MEMBERSHIP_EDITING, false) do
          user_in_org = FactoryGirl.create(:user_in_organisation)
          org_with_user = user_in_org.organisation
          other_organisation = FactoryGirl.create(:organisation, abbreviation: 'ABBR')

          get :edit, id: user_in_org.id

          assert_select "select[name='user[organisation_id]']" do
            assert_select "option", count: 3  # including 'None'
            assert_select "option[selected=selected]", count: 1
            assert_select "option[value=#{org_with_user.id}][selected=selected]", text: org_with_user.name_with_abbreviation
            assert_select "option[value=#{other_organisation.id}]", text: other_organisation.name_with_abbreviation
          end
        end
      end
    end

    context "when editing of user membership of organisations is disabled" do
      should "not show the organisation to which the user belongs" do
        with_const_override(:DISABLE_MEMBERSHIP_EDITING, true) do
          user = FactoryGirl.create(:user)
          organisation = FactoryGirl.create(:organisation)

          get :edit, id: user.id

          assert_select "select[name='user[organisation_id]']", false
          assert_select ".container" do
            assert_select "option", count: 0, text: organisation.name_with_abbreviation
          end
        end
      end
    end
  end

  context "PUT update" do
    should "update the user" do
      another_user = FactoryGirl.create(:user, name: "Old Name")
      put :update, id: another_user.id, user: { name: "New Name" }

      assert_equal "New Name", another_user.reload.name
      assert_equal 200, response.status
      assert_equal "Updated user #{another_user.email} successfully", flash[:notice]
    end

    context "when editing of user membership of organisations is enabled" do
      should "update the user's organisation" do
        with_const_override(:DISABLE_MEMBERSHIP_EDITING, false) do
          user = FactoryGirl.create(:user_in_organisation)

          assert_not_nil user.organisation
          put :update, id: user.id, user: { organisation_id: nil }
          assert_nil user.reload.organisation
        end
      end
    end

    should "redisplay the form if save fails" do
      another_user = FactoryGirl.create(:user)
      put :update, id: another_user.id, user: { name: "" }
      assert_select "form#edit_user_#{another_user.id}"
    end

    should "not let you set the role" do
      not_an_admin = FactoryGirl.create(:user)
      put :update, id: not_an_admin.id, user: { role: "admin" }
      assert_equal "normal", not_an_admin.reload.role
    end

    context "you are a superadmin" do
      setup do
        @user.update_column(:role, "superadmin")
      end

      should "let you set the role" do
        not_an_admin = FactoryGirl.create(:user)
        put :update, id: not_an_admin.id, user: { role: "admin" }
        assert_equal "admin", not_an_admin.reload.role
      end
    end

    context "changing an email" do
      should "stage the change, and send a confirmation email" do
        another_user = FactoryGirl.create(:user, email: "old@email.com")
        put :update, id: another_user.id, user: { email: "new@email.com" }

        another_user.reload
        assert_equal "new@email.com", another_user.reload.unconfirmed_email
        assert_equal "old@email.com", another_user.reload.email
        assert_equal "Confirm your email change", ActionMailer::Base.deliveries.last.subject
      end

      context "an invited-but-not-yet-accepted user" do
        should "change the email, and send a new invitation email" do
          another_user = User.invite!(name: "Ali", email: "old@email.com")
          put :update, id: another_user.id, user: { email: "new@email.com" }

          another_user.reload
          assert_equal "new@email.com", another_user.reload.email
          signup_email = ActionMailer::Base.deliveries.last
          assert_equal "Please confirm your account", signup_email.subject
          assert_equal "new@email.com", signup_email.to[0]
        end
      end
    end

    should "push changes to permissions out to apps (but only those ever used by them)" do
      another_user = FactoryGirl.create(:user)
      app = FactoryGirl.create(:application)
      unused_app = FactoryGirl.create(:application)
      permission = FactoryGirl.create(:permission, application: app, user: another_user)
      permission_for_unused_app = FactoryGirl.create(:permission, application: unused_app, user: another_user)
      # simulate them having used (and 'authorized' the app)
      ::Doorkeeper::AccessToken.create(resource_owner_id: another_user.id, application_id: app.id, token: "1234")

      PermissionUpdater.expects(:new).with(another_user, [app]).returns(mock("mock propagator", attempt: {}))

      permissions_attributes = {
        permissions_attributes: {
          0 => {
            application_id: "#{app.id}",
            id: "#{permission.id}",
            signin_permission: "1",
            permissions: ["banana"]
          }
        }
      }
      put :update, { id: another_user.id, user: { name: "New Name" } }.merge(permissions_attributes)

      assert_equal "New Name", another_user.reload.name
      assert_equal 200, response.status
    end
  end

  context "PUT resend_email_change" do
    should "send an email change confirmation email" do
      another_user = FactoryGirl.create(:user_with_pending_email_change)
      put :resend_email_change, id: another_user.id

      assert_equal "Confirm your email change", ActionMailer::Base.deliveries.last.subject
    end

    should "use a new token if it's expired" do
      another_user = FactoryGirl.create(:user_with_pending_email_change,
                                          confirmation_token: "old token",
                                          confirmation_sent_at: 15.days.ago)
      put :resend_email_change, id: another_user.id

      assert_not_equal "old token", another_user.reload.confirmation_token
    end
  end

  context "DELETE cancel_email_change" do
    should "clear the unconfirmed_email and the confirmation_token" do
      another_user = FactoryGirl.create(:user_with_pending_email_change)
      delete :cancel_email_change, id: another_user.id

      another_user.reload
      assert_equal nil, another_user.unconfirmed_email
      assert_equal nil, another_user.confirmation_token
    end
  end

  should "disallow access to non-admins" do
    @user.update_column(:role, nil)
    get :index
    assert_redirected_to root_path
  end
end
