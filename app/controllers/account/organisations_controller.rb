class Account::OrganisationsController < ApplicationController
  before_action :authenticate_user!
  before_action :authorise_user

  def edit; end

  def update
    organisation_id = params[:user][:organisation_id]
    organisation = Organisation.find(organisation_id)

    if UserUpdate.new(current_user, { organisation_id: }).call
      redirect_to account_path, notice: "Your organisation is now #{organisation.name}"
    else
      flash[:alert] = "There was a problem changing your organisation."
      render :edit
    end
  end

private

  def authorise_user
    authorize %i[account organisations]
  end
end
