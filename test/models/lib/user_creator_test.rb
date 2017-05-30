require 'test_helper'

class UserCreatorTest < ActiveSupport::TestCase
  test 'it creates a new user with the supplied name and email' do
    FactoryGirl.create(:application, name: 'app-o-tron', with_supported_permissions: ['signin'])
    user_creator = UserCreator.new('Alicia', 'alicia@example.com', 'app-o-tron')

    user_creator.create_user!

    assert user_creator.user.persisted?
    assert_equal 'Alicia', user_creator.user.name
    assert_equal 'alicia@example.com', user_creator.user.email
  end

  test 'invites the new user, so they must validate their email before they can signin' do
    FactoryGirl.create(:application, name: 'app-o-tron', with_supported_permissions: ['signin'])
    user_creator = UserCreator.new('Alicia', 'alicia@example.com', 'app-o-tron')

    user_creator.create_user!

    assert user_creator.user.invited_but_not_yet_accepted?
  end

  test 'it grants "signin" permission to each application supplied' do
    app_o_tron = FactoryGirl.create(:application, name: 'app-o-tron', with_supported_permissions: ['signin'])
    app_erator = FactoryGirl.create(:application, name: 'app-erator', with_supported_permissions: ['signin'])
    user_creator = UserCreator.new('Alicia', 'alicia@example.com', 'app-o-tron,app-erator')

    user_creator.create_user!

    assert user_creator.user.has_access_to? app_o_tron
    assert user_creator.user.has_access_to? app_erator
  end
end
