require "test_helper"

class Api::UserPresenterTest < ActiveSupport::TestCase
  context "#present" do
    setup do
      @user = build(:user, organisation: build(:organisation))
    end

    should "return a presented version of the user" do
      presented_user = Api::UserPresenter.present(@user)

      assert_equal presented_user, {
        uid: @user.uid,
        name: @user.name,
        email: @user.email,
        organisation: {
          content_id: @user.organisation.content_id,
          name: @user.organisation.name,
          slug: @user.organisation.slug,
        },
      }
    end

    should "return nil for an organisation" do
      @user.organisation = nil

      presented_user = Api::UserPresenter.present(@user)

      assert_equal presented_user, {
        uid: @user.uid,
        name: @user.name,
        email: @user.email,
        organisation: nil,
      }
    end
  end

  context "#present_many" do
    should "present an array of users" do
      users = build_list(:user, 4)
      result = Api::UserPresenter.present_many(users)

      assert_equal(result, users.map { |u| Api::UserPresenter.present(u) })
    end
  end
end
