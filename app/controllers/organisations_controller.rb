class OrganisationsController < ApplicationController
  before_filter :authenticate_user!

  respond_to :html

  def index
    authorize Organisation
    @organisations = policy_scope(Organisation)
  end
end
