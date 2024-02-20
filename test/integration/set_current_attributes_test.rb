require "test_helper"

class SetCurrentAttributesTest < ActionDispatch::IntegrationTest
  class TestsController < ApplicationController
    cattr_accessor :user, :signed_in_outside_action, :users, :user_ip
    skip_after_action :verify_authorized

    def show
      self.class.users[:within_action] = Current.user
      self.user_ip = Current.user_ip

      head :ok
    end

    def signing_in_within_action
      self.class.users[:before_signing_in] = Current.user
      sign_in(self.class.user)
      self.class.users[:after_signing_in] = Current.user

      head :ok
    end

    def signing_out_within_action
      self.class.users[:before_signing_out] = Current.user
      sign_out
      self.class.users[:after_signing_out] = Current.user

      head :ok
    end

  private

    def current_user
      self.class.signed_in_outside_action ? self.class.user : super
    end
  end

  setup do
    TestsController.user = nil
    TestsController.signed_in_outside_action = false
    TestsController.users = {}
    TestsController.user_ip = nil
  end

  should "set Current.user if user is signed in outside action" do
    with_test_routes do
      user = create(:user)
      TestsController.signed_in_outside_action = true
      TestsController.user = user
      visit "/show"

      assert_equal user, TestsController.users[:within_action]
    end
  end

  should "not set Current.user if user is not signed in outside action" do
    with_test_routes do
      TestsController.signed_in_outside_action = true
      TestsController.user = nil
      visit "/show"

      assert_nil TestsController.users[:within_action]
    end
  end

  should "set Current.user_ip" do
    with_test_routes do
      page.driver.options[:headers] = { "REMOTE_ADDR" => "4.5.6.7" }
      visit "/show"

      assert_equal "4.5.6.7", TestsController.user_ip
    end
  end

  should "set Current.user if user signs in within action" do
    with_test_routes do
      user = create(:user)
      TestsController.user = user
      visit "/signing_in_within_action"

      assert_nil TestsController.users[:before_signing_in]
      assert_equal user, TestsController.users[:after_signing_in]
    end
  end

  should "unset Current.user if user signs out within action" do
    with_test_routes do
      user = create(:user)
      TestsController.signed_in_outside_action = true
      TestsController.user = user
      visit "/signing_out_within_action"

      assert_equal user, TestsController.users[:before_signing_out]
      assert_nil TestsController.users[:after_signing_out]
    end
  end

private

  def with_test_routes
    Rails.application.routes.draw do
      get "/show" => "set_current_attributes_test/tests#show"
      get "/signing_in_within_action" => "set_current_attributes_test/tests#signing_in_within_action"
      get "/signing_out_within_action" => "set_current_attributes_test/tests#signing_out_within_action"
    end
    yield
  ensure
    Rails.application.reload_routes!
  end

  def with_user(user)
    TestsController.user = user
    yield
  ensure
    TestsController.user = nil
  end
end
