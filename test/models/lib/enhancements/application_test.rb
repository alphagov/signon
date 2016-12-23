require 'test_helper'

class ApplicationTest < ActiveSupport::TestCase
  should "act as paranoid" do
    assert ::Doorkeeper::Application.paranoid?
  end

  context "destroying" do
    setup do
      @app = FactoryGirl.create(:application)
      @app.destroy
    end

    should "remove sso push update support" do
      refute @app.reload.supports_push_updates
    end
  end
end
