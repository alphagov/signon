require 'rails_helper'

describe BatchInvitationPolicy do
  subject { described_class }

  permissions :new? do
    it 'allows superadmins and admins to create new batch uploads' do
      expect(subject).to permit(create(:user_in_organisation, role: 'superadmin'), BatchInvitation.new)
      expect(subject).to permit(create(:user_in_organisation, role: 'admin'), BatchInvitation.new)
    end

    context 'organisation admin' do
      let(:organisation_admin) { create(:user_in_organisation, role: 'organisation_admin') }

      it 'allows new batch upload for organisations within their organisation subtree' do
        expect(subject).to permit(organisation_admin, BatchInvitation.new(organisation_id: organisation_admin.organisation_id))
      end

      it 'blocks batch upload for organisations outside their organisation subtree' do
        expect(subject).not_to permit(create(:user_in_organisation, role: 'organisation_admin'), BatchInvitation.new)
        expect(subject).not_to permit(create(:user_in_organisation, role: 'organisation_admin'), BatchInvitation.new(organisation_id: create(:organisation).id))
      end
    end
  end
end
