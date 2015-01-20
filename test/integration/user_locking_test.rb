require 'test_helper'

class UserLockingTest < ActionDispatch::IntegrationTest
  should "trigger if the user typed a wrong password too many times" do
    Sidekiq::Testing.inline!

    user = create(:user)
    visit root_path
    8.times { signin(email: user.email, password: "wrong password") }

    signin(user)

    assert_equal user.email, last_email.to[0]
    assert_equal "Your GOV.UK Signon account has been locked", last_email.subject

    assert_response_contains("Invalid email or passphrase.")

    user.reload
    assert user.access_locked?
  end

  should "enqueue the 'account locked' explanation email" do
    user = create(:user)
    visit root_path

    assert_difference('Sidekiq::Extensions::DelayedMailer.jobs.size', 1) do
      8.times { signin(email: user.email, password: "wrong password") }
    end
  end

  should "be reversible by admins" do
    admin = create(:user, role: "admin")
    user = create(:user)
    user.lock_access!

    visit root_path
    signin(admin)
    first_letter_of_name = user.name[0]
    visit users_path(letter: first_letter_of_name)
    click_button 'Unlock account'

    user.reload
    assert ! user.access_locked?
  end

  should "be reversible from the user edit page" do
    admin = create(:user, role: "admin")
    user = create(:user)
    user.lock_access!

    visit root_path
    signin(admin)
    visit edit_user_path(user)

    click_button 'Unlock account'

    user.reload
    assert ! user.access_locked?
  end
end
