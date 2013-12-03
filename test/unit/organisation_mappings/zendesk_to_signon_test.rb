require 'test_helper'
require Rails.root + 'lib/organisation_mappings/zendesk_to_signon'

class OrganisationMappings::ZendeskToSignonTest < ActiveSupport::TestCase

  test "assigns organisation to users who have recognised domain names" do
    org = FactoryGirl.create(:organisation, name: "Cabinet Office")
    user = FactoryGirl.create(:user, email: 'foo@digital.cabinet-office.gov.uk')

    assert_empty org.users
    OrganisationMappings::ZendeskToSignon.apply
    assert_equal org, user.reload.organisation
  end

  test "doesn't assign organisation to users who don't have a recognised domain name" do
    org = FactoryGirl.create(:organisation, name: "Cabinet Office")
    user = FactoryGirl.create(:user, email: 'foo@mailinator.com')

    OrganisationMappings::ZendeskToSignon.apply
    assert_nil user.organisation
  end

  test "doesn't affect users who belong to an organisation" do
    org = FactoryGirl.create(:organisation, name: "Cabinet Office")
    org.users << (user = FactoryGirl.create(:user, email: 'foo@mailinator.com'))

    OrganisationMappings::ZendeskToSignon.apply
    assert_equal org, user.organisation
  end

end
