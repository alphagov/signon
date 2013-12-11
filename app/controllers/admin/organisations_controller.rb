class Admin::OrganisationsController < ApplicationController
  before_filter :authenticate_user!
  load_and_authorize_resource

  respond_to :html

  def index
    @organisations = Organisation.order(:name)
  end
end
