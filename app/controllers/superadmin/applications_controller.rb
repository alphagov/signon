class Superadmin::ApplicationsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :load_application, except: :index

  respond_to :html

  def index
    @applications = Doorkeeper::Application.all
  end

  def update
    if @application.update_attributes(params[:application])
      redirect_to superadmin_applications_path, notice: "Successfully updated #{@application.name}"
    else
      respond_with @application
    end
  end

  private

  def load_application
    @application = Doorkeeper::Application.find(params[:id])
  end
end
