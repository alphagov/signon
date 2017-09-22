require 'rails_helper'

describe SupportedPermissionPolicy do
  subject { described_class }

  describe described_class::Scope do
    subject { described_class.new(user, SupportedPermission.all) }
    let(:resolved_scope) { subject.resolve }

    let(:app_one) { create(:application, name: 'App one') }
    let(:app_two) { create(:application, name: 'App two') }
    let(:app_three) { create(:application, name: 'App three') }
    let(:app_four) { create(:application, name: 'App four') }

    let!(:app_one_signin_permission) { app_one.signin_permission.tap { |s| s.update_attributes(delegatable: true) } }
    let!(:app_two_signin_permission) { app_two.signin_permission.tap { |s| s.update_attributes(delegatable: false) } }
    let!(:app_three_signin_permission) { app_three.signin_permission.tap { |s| s.update_attributes(delegatable: true) } }
    let!(:app_four_signin_permission) { app_four.signin_permission.tap { |s| s.update_attributes(delegatable: false) } }

    let!(:app_one_hat_permission) { create(:non_delegatable_supported_permission, application: app_one, name: 'hat') }
    let!(:app_one_cat_permission) { create(:delegatable_supported_permission, application: app_one, name: 'cat') }

    let!(:app_two_rat_permission) { create(:non_delegatable_supported_permission, application: app_two, name: 'rat') }
    let!(:app_two_bat_permission) { create(:delegatable_supported_permission, application: app_two, name: 'bat') }

    let!(:app_three_fat_permission) { create(:non_delegatable_supported_permission, application: app_three, name: 'fat') }
    let!(:app_three_vat_permission) { create(:delegatable_supported_permission, application: app_three, name: 'vat') }

    let!(:app_four_pat_permission) { create(:non_delegatable_supported_permission, application: app_three, name: 'pat') }
    let!(:app_four_sat_permission) { create(:delegatable_supported_permission, application: app_three, name: 'sat') }

    context 'for super admins' do
      let(:user) { create(:superadmin_user) }

      it 'includes all permissions' do
        expect(resolved_scope).to include(app_one_signin_permission)
        expect(resolved_scope).to include(app_one_hat_permission)
        expect(resolved_scope).to include(app_one_cat_permission)

        expect(resolved_scope).to include(app_two_signin_permission)
        expect(resolved_scope).to include(app_two_rat_permission)
        expect(resolved_scope).to include(app_two_bat_permission)

        expect(resolved_scope).to include(app_three_signin_permission)
        expect(resolved_scope).to include(app_three_fat_permission)
        expect(resolved_scope).to include(app_three_vat_permission)

        expect(resolved_scope).to include(app_four_signin_permission)
        expect(resolved_scope).to include(app_four_pat_permission)
        expect(resolved_scope).to include(app_four_sat_permission)
      end
    end

    context 'for admins' do
      let(:user) { create(:admin_user) }

      it 'includes all permissions' do
        expect(resolved_scope).to include(app_one_signin_permission)
        expect(resolved_scope).to include(app_one_hat_permission)
        expect(resolved_scope).to include(app_one_cat_permission)

        expect(resolved_scope).to include(app_two_signin_permission)
        expect(resolved_scope).to include(app_two_rat_permission)
        expect(resolved_scope).to include(app_two_bat_permission)

        expect(resolved_scope).to include(app_three_signin_permission)
        expect(resolved_scope).to include(app_three_fat_permission)
        expect(resolved_scope).to include(app_three_vat_permission)

        expect(resolved_scope).to include(app_four_pat_permission)
        expect(resolved_scope).to include(app_four_sat_permission)
      end
    end

    context 'for super organisation admins' do
      let(:user) do
        create(:super_org_admin).tap do |u|
          u.grant_application_permission(app_one, 'signin')
          u.grant_application_permission(app_two, 'signin')
        end
      end

      it 'contains all permissions for apps with delegatable signin permission that the super organisation admin has access to' do
        expect(resolved_scope).to include(app_one_signin_permission)
        expect(resolved_scope).to include(app_one_cat_permission)
        expect(resolved_scope).to include(app_one_hat_permission)
      end

      it 'does not contain any permissions for apps with non-delegatbale signin permission the super organisation admin has access to' do
        expect(resolved_scope).not_to include(app_two_signin_permission)
        expect(resolved_scope).not_to include(app_two_rat_permission)
        expect(resolved_scope).not_to include(app_two_bat_permission)
      end

      it 'does not contain any permissions for apps the super organisation admin does not have access to' do
        expect(resolved_scope).not_to include(app_three_signin_permission)
        expect(resolved_scope).not_to include(app_three_fat_permission)
        expect(resolved_scope).not_to include(app_three_vat_permission)

        expect(resolved_scope).not_to include(app_four_signin_permission)
        expect(resolved_scope).not_to include(app_four_pat_permission)
        expect(resolved_scope).not_to include(app_four_sat_permission)
      end
    end

    context 'for organisation admins' do
      let(:user) do
        create(:organisation_admin).tap do |u|
          u.grant_application_permission(app_one, 'signin')
          u.grant_application_permission(app_two, 'signin')
        end
      end

      it 'contains all permissions for apps with delegatable signin permission that the organisation admin has access to' do
        expect(resolved_scope).to include(app_one_signin_permission)
        expect(resolved_scope).to include(app_one_cat_permission)
        expect(resolved_scope).to include(app_one_hat_permission)
      end

      it 'does not contain any permissions for apps with non-delegatbale signin permission the organisation admin has access to' do
        expect(resolved_scope).not_to include(app_two_signin_permission)
        expect(resolved_scope).not_to include(app_two_rat_permission)
        expect(resolved_scope).not_to include(app_two_bat_permission)
      end

      it 'does not contain any permissions for apps the organisation admin does not have access to' do
        expect(resolved_scope).not_to include(app_three_signin_permission)
        expect(resolved_scope).not_to include(app_three_fat_permission)
        expect(resolved_scope).not_to include(app_three_vat_permission)

        expect(resolved_scope).not_to include(app_four_signin_permission)
        expect(resolved_scope).not_to include(app_four_pat_permission)
        expect(resolved_scope).not_to include(app_four_sat_permission)
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
