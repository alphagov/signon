class BulkUpdate::CloseOrganisationController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_user

  respond_to :html

  def index; end

  def update
    organisation = Organisation.find_by(content_id: params[:organisation_id])
    if organisation
      organisation.update!(closed: true)
      flash[:success_alert] = {
        message: "Organisation closed",
        description: "#{organisation.name} has been marked as closed.",
      }
    else
      flash[:error] = "Organisation does not exist"
      render :index and return
    end
  end

private

  def authorize_user
    authorize User, :bulk_update?
  end
end
