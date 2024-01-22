class OrganisationsController < ApplicationController
  before_action :authenticate_user!

  respond_to :html

  def index
    authorize Organisation
    @organisations = policy_scope(Organisation)
  end

  def update
    authorize Organisation, :edit?
    @organisation = Organisation.find(params[:id])
    if params[:organisation] && params[:organisation][:require_2sv] == "1"
      @organisation.update!(require_2sv: true)
    else
      @organisation.update!(require_2sv: false)
    end
    redirect_to organisations_path
  end

  def edit
    authorize Organisation
    @organisation = Organisation.find(params[:id])
    render :edit
  end
end
