require 'test_helper'

class BatchInvitationUserTest < ActiveSupport::TestCase

  context "invite" do
    setup do
      @inviting_user = create(:admin_user)
    end

    context "success" do
      should "record the outcome against the user" do
        bi = BatchInvitationUser.create!(name: "A", email: "a@m.com")
        bi.invite(@inviting_user, {})

        assert_equal "success", bi.reload.outcome
      end
    end

    context "user already exists" do
      should "record the outcome against the user" do
        create(:user, name: "A", email: "a@m.com")
        bi = BatchInvitationUser.create!(name: "A", email: "a@m.com")
        bi.invite(@inviting_user, {})

        assert_equal "skipped", bi.reload.outcome
      end
    end

    context "the user could not be saved (eg email is blank)" do
      should "record it as a failure" do
        bi = BatchInvitationUser.create!(name: "A", email: "")
        bi.invite(@inviting_user, {})

        assert_equal "failed", bi.reload.outcome
      end
    end

    context "email couldn't be sent" do
      setup do
        Devise::Mailer.any_instance.stubs(:mail).with(anything)
            .raises("SMTP server says no")
      end

      should "record the outcome against the user" do
        bi = BatchInvitationUser.create!(name: "A", email: "a@m.com")
        bi.invite(@inviting_user, {})

        assert_equal "failed", bi.reload.outcome
      end
    end
  end
end
