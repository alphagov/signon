require 'test_helper'

class BatchInvitationTest < ActiveSupport::TestCase
  setup do
    ActionMailer::Base.deliveries = []

    @app = FactoryGirl.create(:application)

    permissions_attributes = {
      0 => {
        application_id: "#{@app.id}",
        id: "",
        permissions: ["signin"]
      }
    }
    @bi = FactoryGirl.create(:batch_invitation, applications_and_permissions: permissions_attributes)
    @user_a = FactoryGirl.create(:batch_invitation_user, name: "A", email: "a@m.com", batch_invitation: @bi)
    @user_b = FactoryGirl.create(:batch_invitation_user, name: "B", email: "b@m.com", batch_invitation: @bi)
  end

  context "perform" do
    should "create the users and assign them permissions" do
      @bi.reload.perform

      user = User.find_by_email("a@m.com")
      assert_not_nil user
      assert_equal "A", user.name

      permissions_for_app = user.permissions.where(application_id: @app.id).first
      assert_not_nil permissions_for_app
      assert_equal ["signin"], permissions_for_app.permissions
    end

    should "trigger an invitation email" do
      @bi.perform

      email = ActionMailer::Base.deliveries.last
      assert_not_nil email
      assert_equal "Please confirm your account", email.subject
      assert_equal ["b@m.com"], email.to
    end

    should "record the outcome against the BatchInvitation" do
      @bi.perform
      assert_equal "success", @bi.outcome
    end

    context "one of the users already exists" do
      setup do
        @user = FactoryGirl.create(:user, name: "Arthur Dent", email: "a@m.com")
        @bi.perform
      end

      should "create the other users" do
        assert_not_nil User.find_by_email("b@m.com")
      end

      should "only send the invitation to the new user" do
        assert_equal 1, ActionMailer::Base.deliveries.size
      end

      should "skip that user entirely, including not altering permissions" do
        app = FactoryGirl.create(:application)
        another_app = FactoryGirl.create(:application)
        FactoryGirl.create(:supported_permission, application_id: another_app.id, name: "foo")
        @user.grant_permissions(another_app, ["signin", "foo"])

        permissions_attributes = {
          0 => {
            application_id: "#{app.id}",
            id: "",
            permissions: []
          },
          1 => {
            application_id: "#{another_app.id}",
            id: "",
            permissions: ["signin"]
          }
        }

        @bi.applications_and_permissions = permissions_attributes
        @bi.save

        @bi.perform

        @user.reload

        app_permissions = @user.permissions.where(application_id: app.id).first
        assert_nil app_permissions

        another_app_permissions = @user.permissions.where(application_id: another_app.id).first
        assert_equal ["signin", "foo"], another_app_permissions.permissions
      end
    end

    context "arbitrary error occurs" do
      should "mark it as failed and pass the error on for DelayedJob to record the error details" do
        BatchInvitationUser.any_instance.expects(:invite).raises("ArbitraryError")

        assert_raises "ArbitraryError" do
          @bi.perform
        end
        assert_equal "fail", @bi.outcome
      end
    end

    context "one of the rows is missing a name or email" do
      setup do
        @user_a.update_column(:name, nil)
        @bi.perform
      end

      should "create the other users" do
        assert_nil User.find_by_email("a@m.com")
        assert_not_nil User.find_by_email("b@m.com")
      end
    end
  end
end
