class AccountsController < ApplicationController
  before_action :authenticate_user!

  def show
    authorize :account_page

    if policy(current_user).edit?
      redirect_to edit_user_path(current_user)
    else
      redirect_to edit_email_or_password_user_path(current_user)
    end
  end
end
