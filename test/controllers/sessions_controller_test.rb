require 'test_helper'

class SessionsControllerTest < ActionController::TestCase
  setup do
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end

  context "GET new" do
    context "when referred by a GOV.UK app" do
      should "store the full referrer to be redirected to later" do
        @request.env["HTTP_REFERER"] = "http://service.dev.gov.uk/bar"
        get :new
        assert_equal "http://service.dev.gov.uk/bar", session["user_return_to"]
      end
    end

    context "when referred by a non GOV.UK url" do
      should "store the root path to be redirected to later" do
        @request.env["HTTP_REFERER"] = "http://attacker.com/bar"
        get :new
        assert_equal "/", session["user_return_to"]
      end
    end
  end
end
