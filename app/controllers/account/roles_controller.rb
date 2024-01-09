class Account::RolesController < ApplicationController
  before_action :authenticate_user!
  before_action :authorise_user

  def edit; end

  def update
    role = params[:user][:role]

    if UserUpdate.new(current_user, { role: }, current_user, user_ip_address).call
      redirect_to account_path, notice: "Your role is now #{role.humanize}"
    else
      flash[:alert] = "There was a problem changing your role."
      render :edit
    end
  end

private

  def authorise_user
    authorize %i[account roles]
  end
end
