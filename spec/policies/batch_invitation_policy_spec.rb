require 'rails_helper'

describe BatchInvitationPolicy do
  subject { described_class }

  [:new?, :create?, :show?].each do |permission_name|
    permissions permission_name do
      it "is forbidden only for normal users" do
        expect(subject).to permit(create(:superadmin_user), User)
        expect(subject).to permit(create(:admin_user), User)
        expect(subject).to permit(create(:organisation_admin), User)

        expect(subject).not_to permit(create(:user), User)
      end
    end
  end

end
