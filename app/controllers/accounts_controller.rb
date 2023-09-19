class AccountsController < ApplicationController
  before_action :authenticate_user!

  def show
    authorize :account_page

    if policy(current_user).edit?
      redirect_to edit_user_path(current_user)
    else
      redirect_to account_email_password_path
    end
  end
end
