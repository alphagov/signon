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
      assert_match /Your .* Signon development account has been locked/, last_email.subject

      assert_response_contains("Invalid email or password.")

      user.reload
      assert user.access_locked?
    end
  end

  should "enqueue the 'account locked' explanation email" do
    user = create(:user)
    visit root_path

    # One job is enqueued to send the email, 9 jobs are enqueued to stream log entries
    # for each incorrect login attempt and the email sending
    assert_enqueued_jobs(10) do
      8.times { signin_with(email: user.email, password: "wrong password") }
    end
  end

  should "be reversible by admins" do
    admin = create(:user, role: "admin")
    user = create(:user)
    user.lock_access!

    visit root_path
    signin_with(admin)
    first_letter_of_name = user.name[0]
    visit users_path(letter: first_letter_of_name)
    click_button "Unlock account"

    user.reload
    assert ! user.access_locked?
  end

  should "be reversible from the user edit page" do
    admin = create(:user, role: "admin")
    user = create(:user)
    user.lock_access!

    visit root_path
    signin_with(admin)
    visit edit_user_path(user)

    click_button "Unlock account"

    user.reload
    assert ! user.access_locked?
  end
end
