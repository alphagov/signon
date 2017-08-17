require 'rails_helper'

describe BulkGrantPermissionSetPolicy do
  subject { described_class }

  permissions :new? do
    it 'allows superadmins to create new bulk grant permission sets' do
      expect(subject).to permit(create(:superadmin_user), BulkGrantPermissionSet.new)
    end

    it 'allows admins to create new bulk grant permission sets' do
      expect(subject).to permit(create(:admin_user), BulkGrantPermissionSet.new)
    end

    it 'is forbidden for super organisation admins' do
      expect(subject).not_to permit(create(:super_org_admin), BulkGrantPermissionSet.new)
    end

    it 'is forbidden for organisation admins' do
      expect(subject).not_to permit(create(:organisation_admin), BulkGrantPermissionSet.new)
    end

    it 'is forbidden for normal users' do
      expect(subject).not_to permit(create(:user), BulkGrantPermissionSet.new)
    end
  end
end
