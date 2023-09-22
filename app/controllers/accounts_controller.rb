class AccountsController < ApplicationController
  layout "admin_layout"

  before_action :authenticate_user!

  def show
    authorize :account_page
  end
end
