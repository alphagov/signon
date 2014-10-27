class Admin::OrganisationsController < ApplicationController
  before_filter :authenticate_user!

  respond_to :html

  def index
    @organisations = Organisation.order(:name)
  end
end
