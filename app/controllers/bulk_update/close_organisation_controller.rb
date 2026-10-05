class BulkUpdate::CloseOrganisationController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_user

  respond_to :html

  def index; end

  def create; end

private

  def authorize_user
    authorize User, :bulk_update?
  end
end
