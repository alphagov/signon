class Superadmin::ApplicationsController < ApplicationController
  before_filter :authenticate_user!
  load_and_authorize_resource class: "Doorkeeper::Application"

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
      redirect_to superadmin_applications_path, notice: "Successfully updated #{@application.name}"
    else
      respond_with @application
    end
  end
end