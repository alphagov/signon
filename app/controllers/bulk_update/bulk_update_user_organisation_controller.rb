class BulkUpdate::BulkUpdateUserOrganisationController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_user

  respond_to :html

  def index; end

  def create
    old_organisation = Organisation.find_by(id: params[:old_organisation_id])
    new_organisation = Organisation.find_by(id: params[:new_organisation_id])
    if old_organisation.nil? || new_organisation.nil?
      flash[:error] = "Organisation does not exist"
    elsif old_organisation == new_organisation
      flash[:error] = "Choose two different organisations"
    elsif new_organisation.closed?
      flash[:error] = "#{new_organisation.name} is closed and cannot receive users"
    else
      users = User.where(organisation: old_organisation)
      user_count = users.count

      begin
        ActiveRecord::Base.transaction do
          users.find_each do |user|
            user.update!(organisation_id: new_organisation.id)

            EventLog.record_organisation_change(
              user,
              old_organisation.name,
              new_organisation.name,
              current_user,
            )
          end
        end

        flash[:success_alert] = {
          message: "Updated users",
          description: "Moved #{user_count} #{'user'.pluralize(user_count)} from #{old_organisation.name} to #{new_organisation.name}",
        }
      rescue ActiveRecord::RecordInvalid => e
        flash[:error] = if e.record.is_a?(User)
                          "Failed to update user: #{e.record.email}"
                        else
                          "Failed to record the organisation change"
                        end
      end
    end
    render :index and return
  end

private

  def authorize_user
    authorize User, :bulk_update?
  end
end
