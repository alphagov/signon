class DoorkeeperApplicationsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :load_and_authorize_application, except: :index

  respond_to :html

  def index
    authorize Doorkeeper::Application
    @applications = Doorkeeper::Application.all
  end

  def update
    if @application.update_attributes(params[:doorkeeper_application])
      redirect_to doorkeeper_applications_path, notice: "Successfully updated #{@application.name}"
    else
      respond_with @application
    end
  end

  private

  def load_and_authorize_application
    @application = Doorkeeper::Application.find(params[:id])
    authorize @application
  end
end
