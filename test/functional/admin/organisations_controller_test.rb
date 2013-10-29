require 'test_helper'

class Admin::OrganisationsControllerTest < ActionController::TestCase

  setup do
    @user = FactoryGirl.create(:user, role: "admin")
    sign_in @user
  end

  context "GET index" do
    setup do
      FactoryGirl.create(:organisation, name: "Ministry of Funk")
    end

    should "list organisations" do
      get :index
      assert_response 200
      assert_select "td", "Ministry of Funk"
    end
  end
end
