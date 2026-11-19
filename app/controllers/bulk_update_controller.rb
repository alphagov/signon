class BulkUpdateController < ApplicationController
  before_action :authenticate_user!

  respond_to :html

  def index
    authorize User, :bulk_update?
  end
end
