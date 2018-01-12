require 'rails_helper'

describe BatchInvitationPolicy do
  subject { described_class }

  permissions :new? do
    it 'allows superadmins and admins to create new batch uploads' do
      expect(subject).to permit(create(:superadmin_user), BatchInvitation.new)
      expect(subject).to permit(create(:admin_user), BatchInvitation.new)
    end

    it 'is forbidden for organisation admins to create new batch uploads even within their organisation subtree' do
      organisation_admin = create(:organisation_admin)

      expect(subject).not_to permit(organisation_admin, BatchInvitation.new)
      expect(subject).not_to permit(organisation_admin, BatchInvitation.new(organisation_id: create(:organisation).id))
      expect(subject).not_to permit(organisation_admin, BatchInvitation.new(organisation_id: organisation_admin.organisation_id))
    end

    it 'is forbidden for super organisation admins to create new batch uploads even within their organisation subtree' do
      super_org_admin = create(:super_org_admin)

      expect(subject).not_to permit(super_org_admin, BatchInvitation.new)
      expect(subject).not_to permit(super_org_admin, BatchInvitation.new(organisation_id: create(:organisation).id))
      expect(subject).not_to permit(super_org_admin, BatchInvitation.new(organisation_id: super_org_admin.organisation_id))
    end

    it 'is forbidden for normal users' do
      expect(subject).not_to permit(create(:user), BatchInvitation.new)
    end
  end

  permissions :assign_organisation_from_csv? do
    it 'is allowed for super admins' do
      expect(subject).to permit(create(:superadmin_user), BatchInvitation.new)
    end

    it 'is forbidden for admins' do
      expect(subject).not_to permit(create(:admin_user), BatchInvitation.new)
    end

    it 'is forbidden for super organisation admins' do
      expect(subject).not_to permit(create(:super_org_admin), BatchInvitation.new)
    end

    it 'is forbidden for organisation admins' do
      expect(subject).not_to permit(create(:organisation_admin), BatchInvitation.new)
    end

    it 'is forbidden for normal users' do
      expect(subject).not_to permit(create(:user), BatchInvitation.new)
    end
  end
end
