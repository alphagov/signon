require "test_helper"

class DataHygieneTaskTest < ActiveSupport::TestCase
  setup do
    Signon::Application.load_tasks if Rake::Task.tasks.empty?

    $stdout.stubs(:write)
  end

  context "#close_organisation" do
    should "mark the organisation as closed" do
      organisation = create(:organisation, slug: "department-of-health", closed: false)

      Rake::Task["data_hygiene:close_organisation"].invoke(organisation.content_id)

      assert organisation.reload.closed?
    end
  end

  context "#bulk_update_user_organisation" do
    should "update the organisation for matching users" do
      old_organisation = create(:organisation, slug: "department-of-health-old")
      new_organisation = create(:organisation, slug: "department-of-health-new")
      another_organisation = create(:organisation, slug: "department-of-other-stuff")

      user_1 = create(:user, organisation: old_organisation)
      user_2 = create(:user, organisation: another_organisation)

      Rake::Task["data_hygiene:bulk_update_user_organisation"].invoke(old_organisation.content_id, new_organisation.content_id)

      assert_equal new_organisation, user_1.reload.organisation
      assert_equal another_organisation, user_2.reload.organisation
    end
  end
end
