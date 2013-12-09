class Superadmin::SupportedPermissionsController < ApplicationController
  before_filter :authenticate_user!
  load_and_authorize_resource :application, class: "Doorkeeper::Application"
  load_and_authorize_resource :supported_permission, through: :application, class: "Doorkeeper::Application"

  respond_to :html

  def new
    @supported_permission = @application.supported_permissions.build
  end

  def edit
    @supported_permission = SupportedPermission.find(params[:id])
  end

  def create
    @supported_permission = @application.supported_permissions.build(supported_permission_parameters)
    if @supported_permission.save
      redirect_to superadmin_application_supported_permissions_path,
        notice: "Successfully added permission #{@supported_permission.name} to #{@application.name}"
    else
      render :new
    end
  end

  def update
    @supported_permission = SupportedPermission.find(params[:id])
    if @supported_permission.update_attributes(supported_permission_parameters)
      redirect_to superadmin_application_supported_permissions_path,
        notice: "Successfully updated permission #{@supported_permission.name}"
    else
      render :edit
    end
  end

private

  def supported_permission_parameters
    params[:supported_permission].slice(:name, :delegatable)
  end

end
