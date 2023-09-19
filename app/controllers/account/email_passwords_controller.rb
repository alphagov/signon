class Account::EmailPasswordsController < ApplicationController
  layout "admin_layout"

  before_action :authenticate_user!
  before_action :authorise_user

  def show; end

private

  def authorise_user
    authorize %i[account email_passwords]
  end
end
