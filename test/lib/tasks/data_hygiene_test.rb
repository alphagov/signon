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
end
