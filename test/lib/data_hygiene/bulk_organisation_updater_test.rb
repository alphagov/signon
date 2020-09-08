require "test_helper"

class DataHygiene::BulkOrganisationUpdaterTest < ActiveSupport::TestCase
  def process(csv_file)
    file = Tempfile.new("bulk_update_organisation")
    file.write(csv_file)
    file.close

    begin
      DataHygiene::BulkOrganisationUpdater.call(file.path)
    ensure
      file.unlink
    end
  end

  test "it fails with invalid CSV data" do
    csv_file = <<~CSV
      old email,New email address,replacement organisation
      a@b.com,d@c.com,new-organisation
    CSV

    assert_raises KeyError do
      process(csv_file)
    end
  end

  test "it fails if the user doesn't exist" do
    csv_file = <<~CSV
      Old email,New email,New organisation
      a@b.com,b@c.com,new-organisation
    CSV

    assert_not process(csv_file)
  end

  test "it changes the email address" do
    csv_file = <<~CSV
      Old email,New email,New organisation
      a@b.com,c@d.com,organisation
    CSV

    organisation = create(:organisation, slug: "organisation")
    user = create(:user, email: "a@b.com", organisation: organisation)

    process(csv_file)

    assert_equal user.reload.email, "c@d.com"
  end

  test "it changes the organisation" do
    csv_file = <<~CSV
      Old email,New email,New organisation
      a@b.com,a@b.com,new-organisation
    CSV

    new_organisation = create(:organisation, slug: "new-organisation")
    user = create(:user, email: "a@b.com")

    process(csv_file)

    assert_equal user.reload.organisation, new_organisation
  end
end
