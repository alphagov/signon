class OrganisationsController < ApplicationController
  before_action :authenticate_user!

  respond_to :html

  def index
    authorize Organisation
    @organisations = policy_scope(Organisation)
  end
end
