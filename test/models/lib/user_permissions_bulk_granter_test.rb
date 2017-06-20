require 'test_helper'

class UserPermissionsBulkGranterTest < ActiveSupport::TestCase
  context '.new' do
    should 'raises an error if the supplied application cannot be found' do
      assert_raises(RuntimeError) do
        UserPermissionsBulkGranter.new('application-that-does-not-exist')
      end
    end

    should 'fetches the supplied application' do
      application = FactoryGirl.create(:application, name: 'application-that-does-exist')
      bulk_granter = UserPermissionsBulkGranter.new('application-that-does-exist')

      assert_equal application, bulk_granter.application
    end
  end
  context '#grant' do
    setup do
      @application = FactoryGirl.create(:application, name: 'application-that-does-exist', with_supported_permissions: ['signin'])
      @bulk_granter = UserPermissionsBulkGranter.new('application-that-does-exist')
    end

    should 'raises an error if the supplied permission does not exist for the application' do
      assert_raises(RuntimeError) do
        @bulk_granter.grant('be-a-super-admin')
      end
    end

    should 'adds the permission to an active user' do
      user = FactoryGirl.create(:user)
      @bulk_granter.grant('signin')
      assert user.reload.permissions_for(@application).include? 'signin'
    end

    should 'adds the permission to a suspended user' do
      user = FactoryGirl.create(:suspended_user)
      @bulk_granter.grant('signin')
      assert user.reload.permissions_for(@application).include? 'signin'
    end

    should 'adds the permission to an api user' do
      user = FactoryGirl.create(:api_user)
      @bulk_granter.grant('signin')
      assert user.reload.permissions_for(@application).include? 'signin'
    end

    should 'does not break when adding the permission to a user that user already has it' do
      # The real assertion here is that the test doesn't explode when it
      # tries to add the permission, not that the permission is there
      user = FactoryGirl.create(:user, with_signin_permissions_for: [@application])
      @bulk_granter.grant('signin')
      assert user.reload.permissions_for(@application).include? 'signin'
    end
  end
end
