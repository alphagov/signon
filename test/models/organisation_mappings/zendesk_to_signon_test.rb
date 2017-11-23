require 'test_helper'
require Rails.root + 'lib/organisation_mappings/zendesk_to_signon'

class OrganisationMappings::ZendeskToSignonTest < ActiveSupport::TestCase
  # Reimplemtation of silence_stream as it was removed in Rails 5
  def silence_stream(stream, &_block)
    begin
      old_stream = stream.dup
      stream.reopen(File::NULL)
      stream.sync = true

      yield

    ensure
      stream.reopen(old_stream)
      old_stream.close

    end
  end

  def apply_mappings
    silence_stream(STDOUT) do # to stop warnings about missing orgs from printing out during test execution
      OrganisationMappings::ZendeskToSignon.apply
    end
  end


  test "assigns organisation to users who have recognised domain names" do
    co = create(:organisation, name: "Cabinet Office")
    user = create(:user, email: 'foo@digital.cabinet-office.gov.uk')

    assert_empty co.users
    apply_mappings
    assert_equal co, user.reload.organisation
  end

  test "doesn't assign organisation to users who don't have a recognised domain name" do
    co = create(:organisation, name: "Cabinet Office")
    user = create(:user, email: 'foo@mailinator.com')

    apply_mappings
    assert_nil user.organisation
  end

  test "doesn't affect users who belong to an organisation" do
    hmrc = create(:organisation, name: "HM Revenue & Customs")
    co = create(:organisation, name: "Cabinet Office")
    co.users << (co_user = create(:user, email: 'someone.important@hmrc.gsi.gov.uk'))

    apply_mappings
    assert_equal co, co_user.reload.organisation
  end
end
