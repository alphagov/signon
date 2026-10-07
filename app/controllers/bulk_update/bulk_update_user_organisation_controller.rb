class BulkUpdate::BulkUpdateUserOrganisationController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_user

  respond_to :html

  def index; end

  def update
    old_organisation = Organisation.find_by(id: params[:old_organisation_id])
    new_organisation = Organisation.find_by(id: params[:new_organisation_id])
    if old_organisation && new_organisation
      users = User.where(organisation: old_organisation)
      user_count = users.count

      users.each do |user|
        EventLog.record_organisation_change(
          user,
          old_organisation.name,
          new_organisation.name,
          current_user,
        )
      end

      users.update_all(organisation_id: new_organisation.id)

      flash[:success_alert] = {
        message: "Updated users",
        description: "Moved #{user_count} users from #{old_organisation.name} to #{new_organisation.name}",
      }
    else
      flash[:error] = "Organisation does not exist"
    end
    render :index and return
  end

private

  def authorize_user
    authorize User, :bulk_update?
  end
end
