require 'rails_helper'

describe ApplicationPolicy do
  subject { described_class }

  [:index?, :edit?, :update?, :manage_supported_permissions?, :users_with_access?].each do |permission_name|
    permissions permission_name do
      it "is allowed only for superadmins" do
        expect(subject).to permit(create(:superadmin_user), User)

        expect(subject).not_to permit(create(:admin_user), User)
        expect(subject).not_to permit(create(:super_org_admin), User)
        expect(subject).not_to permit(create(:organisation_admin), User)
        expect(subject).not_to permit(create(:user), User)
      end
    end
  end
end
