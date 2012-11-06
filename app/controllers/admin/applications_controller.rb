class Admin::ApplicationsController < Admin::BaseController
  respond_to :html

  def index
    @applications = ::Doorkeeper::Application.order(:name).all
  end

  def edit
    @application = ::Doorkeeper::Application.find(params[:id])
  end

  def update
    @application = ::Doorkeeper::Application.find(params[:id])
    if @application.update_attributes(params[:application])
      redirect_to admin_applications_path, notice: "Successfully updated #{@application.name}"
    else
      respond_with @application
    end
  end
end