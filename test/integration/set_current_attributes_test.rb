require "test_helper"

class SetCurrentAttributesTest < ActionDispatch::IntegrationTest
  class TestsController < ApplicationController
    cattr_accessor :current_user
    skip_after_action :verify_authorized

    def show
      render json: { user_id: Current.user&.id, user_ip: Current.user_ip }
    end

  private

    def current_user
      self.class.current_user
    end
  end

  should "set Current.user if user is signed in" do
    with_test_route do
      user = create(:user)
      with_current_user(user) do
        visit "/test"

        assert_equal user.id, JSON.parse(page.body)["user_id"]
      end
    end
  end

  should "not set Current.user if user is not signed in" do
    with_test_route do
      with_current_user(nil) do
        visit "/test"

        assert_nil JSON.parse(page.body)["user_id"]
      end
    end
  end

  should "set Current.user_ip" do
    with_test_route do
      page.driver.options[:headers] = { "REMOTE_ADDR" => "4.5.6.7" }
      visit "/test"

      assert_equal "4.5.6.7", JSON.parse(page.body)["user_ip"]
    end
  end

private

  def with_test_route
    Rails.application.routes.draw do
      get "/test" => "set_current_attributes_test/tests#show"
    end
    yield
  ensure
    Rails.application.reload_routes!
  end

  def with_current_user(user)
    TestsController.current_user = user
    yield
  ensure
    TestsController.current_user = nil
  end
end
