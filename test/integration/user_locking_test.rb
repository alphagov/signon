require 'test_helper'
 
class UserLockingTest < ActionDispatch::IntegrationTest
  should "trigger if the user typed a wrong password too many times" do
    user = create(:user)
    visit root_path
    8.times { signin(email: user.email, password: "wrong password") }

    signin(user)
    assert_response_contains("Invalid email or passphrase.")

    user.reload
    assert user.access_locked?
  end

  should "be reversible by admins" do
    admin = create(:user, role: "admin")
    user = create(:user)
    user.lock_access!

    visit root_path
    signin(admin)
    first_letter_of_name = user.name[0]
    visit admin_users_path(letter: first_letter_of_name)
    click_button 'Unlock'

    user.reload
    assert ! user.access_locked?
  end
end
