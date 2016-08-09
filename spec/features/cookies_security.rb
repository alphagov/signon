require 'rails_helper'

feature 'cookies security' do
  scenario 'with valid email and password' do
    user = FactoryGirl.create(:two_step_enabled_user)
    sign_up_with user.email, user.password
    visit new_user_session_path
    response_cookies = Capybara.current_session.driver.response.headers["Set-Cookie"]
    expect(response_cookies).to include('HttpOnly')
    expect(response_cookies).to include('SameSite=Lax')
  end

  def sign_up_with(email, password)
    visit new_user_session_path
    fill_in 'Email', with: email
    fill_in 'Passphrase', with: password
    click_button 'Sign in'
  end
end
