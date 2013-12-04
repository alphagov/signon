require 'test_helper'
require Rails.root + 'lib/organisation_mappings/zendesk_to_signon'

class OrganisationMappings::ZendeskToSignonTest < ActiveSupport::TestCase

  test "assigns organisation to users who have recognised domain names" do
    co = FactoryGirl.create(:organisation, name: "Cabinet Office")
    user = FactoryGirl.create(:user, email: 'foo@digital.cabinet-office.gov.uk')

    assert_empty co.users
    OrganisationMappings::ZendeskToSignon.apply
    assert_equal co, user.reload.organisation
  end

  test "doesn't assign organisation to users who don't have a recognised domain name" do
    co = FactoryGirl.create(:organisation, name: "Cabinet Office")
    user = FactoryGirl.create(:user, email: 'foo@mailinator.com')

    OrganisationMappings::ZendeskToSignon.apply
    assert_nil user.organisation
  end

  test "doesn't affect users who belong to an organisation" do
    hmrc = FactoryGirl.create(:organisation, name: "HM Revenue & Customs")
    co = FactoryGirl.create(:organisation, name: "Cabinet Office")
    co.users << (co_user = FactoryGirl.create(:user, email: 'someone.important@hmrc.gsi.gov.uk'))

    OrganisationMappings::ZendeskToSignon.apply
    assert_equal co, co_user.reload.organisation
  end

end
