require 'test_helper'

class BatchInvitationsHelperTest < ActionView::TestCase
  context '#batch_invite_organisation_for_user' do
    context 'when the batch invitation user raises an invalid slug error when asked for organisation_id' do
      setup do
        @user = FactoryBot.create(:batch_invitation_user, organisation_slug: 'department-of-hats')
      end

      should 'return the empty string' do
        assert_equal '', batch_invite_organisation_for_user(@user)
      end
    end

    context 'when the batch invitation user raises an active record not found error when asked for organisation_id' do
      setup do
        @invite = FactoryBot.create(:batch_invitation, organisation_id: -1)
        @user = FactoryBot.create(:batch_invitation_user, organisation_slug: nil, batch_invitation: @invite)
      end

      should 'return the empty string' do
        assert_equal '', batch_invite_organisation_for_user(@user)
      end
    end

    context 'when the batch invitation user has a valid organisation_slug' do
      setup do
        @org = FactoryBot.create(:organisation, name: 'Department of Hats', slug: 'department-of-hats')
        @user = FactoryBot.create(:batch_invitation_user, organisation_slug: @org.slug)
      end

      should 'return the name of the organisation' do
        assert_equal 'Department of Hats', batch_invite_organisation_for_user(@user)
      end
    end

    context 'when the batch invitation user has a valid organisation from the batch invite' do
      setup do
        @org = FactoryBot.create(:organisation, name: 'Department of Hats', slug: 'department-of-hats')
        @invite = FactoryBot.create(:batch_invitation, organisation: @org)
        @user = FactoryBot.create(:batch_invitation_user, organisation_slug: nil, batch_invitation: @invite)
      end

      should 'return the name of the organisation' do
        assert_equal 'Department of Hats', batch_invite_organisation_for_user(@user)
      end
    end
  end
end
