require "test_helper"

class UserLockingTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  should "trigger if the user typed a wrong password too many times" do
    perform_enqueued_jobs do
      user = create(:user)
      visit root_path
      8.times { signin_with(email: user.email, password: "wrong password") }

      signin_with(user)

      assert_equal user.email, last_email.to[0]
      assert_match(/Your .* Signon test account has been locked/, last_email.subject)

      assert_response_contains("Invalid email or password.")

      user.reload
      assert user.access_locked?
    end
  end

  should "enqueue the 'account locked' explanation email" do
    user = create(:user)
    visit root_path

    assert_no_enqueued_emails do
      (User.maximum_attempts - 1).times { signin_with(email: user.email, password: "wrong password") }
    end

    assert_enqueued_emails(1) do
      signin_with(email: user.email, password: "wrong password")
    end
  end

  should "be reversible from the user edit page" do
    admin = create(:admin_user)
    user = create(:user)
    user.lock_access!

    visit root_path
    signin_with(admin)
    visit edit_user_path(user)

    click_link "Unlock account"
    click_button "Unlock account"

    user.reload
    assert_not user.access_locked?
  end
end
