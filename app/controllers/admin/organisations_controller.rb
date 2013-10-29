class Admin::OrganisationsController < Admin::BaseController
  respond_to :html

  def index
    @organisations = Organisation.order(:name)
  end
end
