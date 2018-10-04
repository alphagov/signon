class OrganisationsController < ApplicationController
  layout "admin_layout"

  before_action :authenticate_user!

  respond_to :html

  def index
    authorize Organisation
    @organisations = policy_scope(Organisation)
  end
end
