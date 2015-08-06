require 'test_helper'

class OrganisationsControllerTest < ActionController::TestCase
  setup do
    @user = create(:admin_user)
    sign_in @user
  end

  context "GET index" do
    setup do
      create(:organisation, name: "Ministry of Funk")
    end

    should "list organisations" do
      get :index
      assert_response 200
      assert_select "td", "Ministry of Funk"
    end
  end
end
