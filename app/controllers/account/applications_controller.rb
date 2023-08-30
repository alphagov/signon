class Account::ApplicationsController < ApplicationController
  layout "admin_layout"

  before_action :authenticate_user!

  def index
    authorize :account_applications

    @applications = Doorkeeper::Application.can_signin(current_user)
  end
end
