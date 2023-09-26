class Account::RoleOrganisationsController < ApplicationController
  layout "admin_layout"

  before_action :authenticate_user!
  before_action :authorise_user

  def show; end

  def update_organisation
    organisation_id = params[:user][:organisation_id]
    organisation = Organisation.find(organisation_id)

    if UserUpdate.new(current_user, { organisation_id: }, current_user, user_ip_address).call
      redirect_to account_path, notice: "Your organisation is now #{organisation.name}"
    else
      flash[:alert] = "There was a problem changing your organisation."
      render :show
    end
  end

  def update_role
    role = params[:user][:role]

    if UserUpdate.new(current_user, { role: }, current_user, user_ip_address).call
      redirect_to account_path, notice: "Your role is now #{role.humanize}"
    else
      flash[:alert] = "There was a problem changing your role."
      render :show
    end
  end

private

  def authorise_user
    authorize %i[account role_organisations]
  end
end
