class Admin::SupportedPermissionsController < Admin::BaseController
  respond_to :html

  def index
    @application = ::Doorkeeper::Application.find(params[:application_id])
  end

  def new
    @application = ::Doorkeeper::Application.find(params[:application_id])
  end

  def create
    @application = ::Doorkeeper::Application.find(params[:application_id])
    newPermission = params[:post][:permission]
    if newPermission.blank?
      redirect_to admin_application_supported_permissions_path, alert: "Failed to add permission to #{@application.name}. Field was blank."
    else
      begin
        SupportedPermission.create(:application_id => params[:application_id], :name => newPermission)
        redirect_to admin_application_supported_permissions_path, notice: "Successfully added permission #{newPermission} to #{@application.name}"
      rescue ActiveRecord::RecordNotUnique => exception
        redirect_to admin_application_supported_permissions_path, alert: "Failed to add permission #{newPermission} to #{@application.name} as it already exists"
      end
    end
  end
end