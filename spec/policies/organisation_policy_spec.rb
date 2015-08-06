require 'rails_helper'

describe OrganisationPolicy do
  subject { described_class }

  permissions :index? do
    it "is forbidden only for normal users" do
      expect(subject).to permit(create(:superadmin_user), Organisation)
      expect(subject).to permit(create(:admin_user), Organisation)
      expect(subject).to permit(create(:organisation_admin), Organisation)

      expect(subject).not_to permit(create(:user), Organisation)
    end
  end

  permissions :can_assign? do
    it "allows superadmins and admins to assign a user to any organisation" do
      expect(subject).to permit(create(:user_in_organisation, role: 'superadmin'), build(:organisation))
      expect(subject).to permit(create(:user_in_organisation, role: 'admin'), build(:organisation))
    end

    it "allows organisation admins to assign a user only to organisations within their organisation subtree" do
      organisation_admin = create(:organisation_admin)
      admins_organisation = organisation_admin.organisation
      child_organisation = create(:organisation, parent_id: admins_organisation.id)

      expect(subject).to permit(organisation_admin, admins_organisation)
      expect(subject).to permit(organisation_admin, child_organisation)

      expect(subject).not_to permit(organisation_admin, build(:organisation))
    end
  end
end
