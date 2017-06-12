require 'rails_helper'

describe BatchInvitationPolicy do
  subject { described_class }

  permissions :new? do
    it 'allows superadmins and admins to create new batch uploads' do
      expect(subject).to permit(create(:user_in_organisation, role: 'superadmin'), BatchInvitation.new)
      expect(subject).to permit(create(:user_in_organisation, role: 'admin'), BatchInvitation.new)
    end

    it 'is forbidden for organisation admins to create new batch uploads even within their organisation subtree' do
      organisation_admin = create(:user_in_organisation, role: 'organisation_admin')

      expect(subject).not_to permit(organisation_admin, BatchInvitation.new)
      expect(subject).not_to permit(organisation_admin, BatchInvitation.new(organisation_id: create(:organisation).id))
      expect(subject).not_to permit(organisation_admin, BatchInvitation.new(organisation_id: organisation_admin.organisation_id))
    end

    it 'is forbidden for normal users' do
      expect(subject).not_to permit(create(:user), BatchInvitation.new)
    end
  end
end
