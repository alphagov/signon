class AccountsController < ApplicationController
  before_action :authenticate_user!

  def show
    authorize :account_page
  end
end
