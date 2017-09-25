require 'rails_helper'

describe OrganisationPolicy do
  subject { described_class }

  permissions :index? do
    it "is forbidden to super organisation admins, organisation admins and normal users" do
      expect(subject).to permit(create(:superadmin_user), Organisation)
      expect(subject).to permit(create(:admin_user), Organisation)

      expect(subject).not_to permit(create(:super_org_admin), Organisation)
      expect(subject).not_to permit(create(:organisation_admin), Organisation)
      expect(subject).not_to permit(create(:user), Organisation)
    end
  end

  permissions :can_assign? do
    it "allows superadmins and admins to assign a user to any organisation" do
      expect(subject).to permit(create(:user_in_organisation, role: 'superadmin'), build(:organisation))
      expect(subject).to permit(create(:user_in_organisation, role: 'admin'), build(:organisation))
    end

    it "is forbidden for super organisation admins" do
      super_org_admin = create(:super_org_admin)
      admins_organisation = super_org_admin.organisation
      child_organisation = create(:organisation, parent_id: admins_organisation.id)

      # can't assign some random org
      expect(subject).not_to permit(super_org_admin, build(:organisation))
      # can't assign the org they are an admin for
      expect(subject).not_to permit(super_org_admin, admins_organisation)
      # can't assign an org that is in the subtree of the one they are an admin for
      expect(subject).not_to permit(super_org_admin, child_organisation)
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
    let!(:parent_organisation) { create(:organisation) }
    let!(:child_organisation_one) { create(:organisation, parent: parent_organisation) }
    let!(:child_organisation_two) { create(:organisation, parent: parent_organisation) }
    let!(:grandchild_organisation_one) { create(:organisation, parent: child_organisation_one) }
    let!(:second_parent_organisation) { create(:organisation) }
    let!(:child_second_organisation) { create(:organisation, parent: second_parent_organisation) }
    subject { described_class.new(user, Organisation.all) }
    let(:resolved_scope) { subject.resolve }

    context 'for super admins' do
      let(:user) { create(:superadmin_user) }

      it 'includes all organisations' do
        expect(resolved_scope).to include(parent_organisation)
        expect(resolved_scope).to include(child_organisation_one)
        expect(resolved_scope).to include(child_organisation_two)
        expect(resolved_scope).to include(grandchild_organisation_one)
        expect(resolved_scope).to include(second_parent_organisation)
        expect(resolved_scope).to include(child_second_organisation)
      end
    end

    context 'for admins' do
      let(:user) { create(:admin_user) }

      it 'includes all organisations' do
        expect(resolved_scope).to include(parent_organisation)
        expect(resolved_scope).to include(child_organisation_one)
        expect(resolved_scope).to include(child_organisation_two)
        expect(resolved_scope).to include(grandchild_organisation_one)
        expect(resolved_scope).to include(second_parent_organisation)
        expect(resolved_scope).to include(child_second_organisation)
      end
    end

    context 'for super organisation admins' do
      let(:user) { create(:super_org_admin, organisation: parent_organisation) }

      it 'is empty' do
        expect(resolved_scope).to be_empty
      end
    end

    context 'for organisation admins' do
      let(:user) { create(:organisation_admin, organisation: parent_organisation) }

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
