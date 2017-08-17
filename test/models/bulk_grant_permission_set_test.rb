require 'test_helper'

class BulkGrantPermissionSetTest < ActiveSupport::TestCase
  setup do
    @app = create(:application)
    @permission_set = create(:bulk_grant_permission_set, with_permissions: [@app.signin_permission])
  end

  should "require a user" do
    permission_set = build(:bulk_grant_permission_set, user: nil)

    refute permission_set.valid?
    assert_equal ["can't be blank"], permission_set.errors[:user]
  end

  should "require at least one supported permission" do
    permission_set = build(:bulk_grant_permission_set, with_permissions: [])

    refute permission_set.valid?
    assert_equal ["must add at least one permission to grant to all users"], permission_set.errors[:supported_permissions]
  end

  context "validating #outcome" do
    should "allow nil" do
      permission_set = build(:bulk_grant_permission_set, outcome: nil)

      assert permission_set.valid?
    end

    should "allow 'success'" do
      permission_set = build(:bulk_grant_permission_set, outcome: 'success')

      assert permission_set.valid?
    end

    should "allow 'fail'" do
      permission_set = build(:bulk_grant_permission_set, outcome: 'fail')

      assert permission_set.valid?
    end

    should "reject other values" do
      permission_set = build(:bulk_grant_permission_set, outcome: 'unsucessful')

      refute permission_set.valid?
      assert_equal ["is not included in the list"], permission_set.errors[:outcome]
    end
  end

  context "perform" do
    should "grant the supplied permissions to all users" do
      user = create(:user)
      admin_user = create(:admin_user)
      superadmin_user = create(:superadmin_user)
      orgadmin_user = create(:organisation_admin)

      @permission_set.perform

      assert_equal %w(signin), user.permissions_for(@app)
      assert_equal %w(signin), admin_user.permissions_for(@app)
      assert_equal %w(signin), superadmin_user.permissions_for(@app)
      assert_equal %w(signin), orgadmin_user.permissions_for(@app)
    end

    should "record the outcome against the BulkGrantPermissionSet" do
      @permission_set.perform
      assert_equal "success", @permission_set.outcome
    end

    should "not fail if a user already has one of the supplied permissions" do
      user = create(:user, with_permissions: { @app => %w(signin) })

      @permission_set.perform

      assert_equal %w(signin), user.permissions_for(@app)
    end

    should "not remove permissions a user has that are not part of the supplied ones for the bulk grant set" do
      other_app = create(:application, with_supported_permissions: %w(editor))
      create(:supported_permission, application: @app, name: 'admin')
      user = create(:user, with_permissions: { other_app => %w(editor), @app => %w(admin) })

      @permission_set.perform

      assert_equal %w(editor), user.permissions_for(other_app)
      assert_equal %w(signin admin).sort, user.permissions_for(@app).sort
    end

    should "mark it as failed if there is an error during processing and pass the error on for the worker to record the error details" do
      UserApplicationPermission.any_instance.expects(:save!).raises("ArbitraryError")

      assert_raises RuntimeError, "ArbitraryError" do
        @permission_set.perform
      end
      assert_equal "fail", @permission_set.outcome
    end
  end
end
