require 'test_helper'

class ::Doorkeeper::ApplicationTest < ActiveSupport::TestCase
  context "supported_permission_strings" do
    should "return a list of string permissions, merging in the defaults" do
      app = FactoryGirl.create(:application)
      FactoryGirl.create(:supported_permission, name: "write", application: app)
      assert_equal ["signin", "write"], app.supported_permission_strings
    end
  end
end
