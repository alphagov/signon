require 'rails_helper'

describe OrganisationPolicy do
  subject { described_class }

  permissions :index? do
    it "is forbidden to organisation admins and normal users" do
      expect(subject).to permit(create(:superadmin_user), Organisation)
      expect(subject).to permit(create(:admin_user), Organisation)

      expect(subject).not_to permit(create(:organisation_admin), Organisation)
      expect(subject).not_to permit(create(:user), Organisation)
    end
  end

  permissions :can_assign? do
    it "allows superadmins and admins to assign a user to any organisation" do
      expect(subject).to permit(create(:user_in_organisation, role: 'superadmin'), build(:organisation))
      expect(subject).to permit(create(:user_in_organisation, role: 'admin'), build(:organisation))
    end

    it "is forbidden for organisation admins" do
      organisation_admin = create(:organisation_admin)
      admins_organisation = organisation_admin.organisation
      child_organisation = create(:organisation, parent_id: admins_organisation.id)

      # can't assign some random org
      expect(subject).not_to permit(organisation_admin, build(:organisation))
      # can't assign the org they are an admin for
      expect(subject).not_to permit(organisation_admin, admins_organisation)
      # can't assign an org that is in the subtree of the one they are an admin for
      expect(subject).not_to permit(organisation_admin, child_organisation)
    end
  end

  describe described_class::Scope do
    let!(:org_root_one) { create(:organisation) }
    let!(:org_root_one_child_one) { create(:organisation, parent: org_root_one) }
    let!(:org_root_one_child_two) { create(:organisation, parent: org_root_one) }
    let!(:org_root_one_grandchild_one) { create(:organisation, parent: org_root_one_child_one) }
    let!(:org_root_two) { create(:organisation) }
    let!(:org_root_two_child_one) { create(:organisation, parent: org_root_two) }
    subject { described_class.new(user, Organisation.all) }
    let(:resolved_scope) { subject.resolve }

    context 'for super admins' do
      let(:user) { create(:superadmin_user) }

      it 'includes all organisations' do
        expect(resolved_scope).to include(org_root_one)
        expect(resolved_scope).to include(org_root_one_child_one)
        expect(resolved_scope).to include(org_root_one_child_two)
        expect(resolved_scope).to include(org_root_one_grandchild_one)
        expect(resolved_scope).to include(org_root_two)
        expect(resolved_scope).to include(org_root_two_child_one)
      end
    end

    context 'for admins' do
      let(:user) { create(:admin_user) }

      it 'includes all organisations' do
        expect(resolved_scope).to include(org_root_one)
        expect(resolved_scope).to include(org_root_one_child_one)
        expect(resolved_scope).to include(org_root_one_child_two)
        expect(resolved_scope).to include(org_root_one_grandchild_one)
        expect(resolved_scope).to include(org_root_two)
        expect(resolved_scope).to include(org_root_two_child_one)
      end
    end

    context 'for org admins' do
      let(:user) { create(:organisation_admin, organisation: org_root_one) }

      it 'is empty' do
        expect(resolved_scope).to be_empty
      end
    end

    context 'for normal users' do
      let(:user) { create(:user) }

      it 'is empty' do
        expect(resolved_scope).to be_empty
      end
    end
  end
end
