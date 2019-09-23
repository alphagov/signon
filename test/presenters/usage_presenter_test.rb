require "test_helper"

class UsagePresenterTest < ActiveSupport::TestCase
  should "create the directory if it does not exist" do
    fake_fs = Object.new
    fake_file_utils = mock

    dir = "/my/fancy/directory"
    report_file = Tempfile.new("report.csv")

    start_date = Date.parse("2018-01-01")
    end_date = Date.parse("2018-10-01")
    usage_presenter = UsagePresenter.new(start_date, end_date, fake_fs, fake_file_utils)

    fake_fs.stubs(:directory?).returns(false)
    fake_fs.stubs(:join).returns(report_file)

    fake_file_utils.expects(:mkdir_p).once

    usage_presenter.write_csv(dir)

    report_file.unlink
  end
end
