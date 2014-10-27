class Superadmin::ApplicationsController < ApplicationController
  before_filter :authenticate_user!

  respond_to :html

  def update
    if @application.update_attributes(params[:application])
      redirect_to superadmin_applications_path, notice: "Successfully updated #{@application.name}"
    else
      respond_with @application
    end
  end
end
