require 'rails_helper'

describe UserPermissionManageableApplicationPolicy do
  subject { described_class }

  describe described_class::Scope do
    subject { described_class.new(acting_user) }
    let(:resolved_scope) { subject.resolve }

    let(:app_one) { create(:application, name: 'App one') }
    let(:app_two) { create(:application, name: 'App two') }
    let(:app_three) { create(:application, name: 'App three') }
    let(:app_four) { create(:application, name: 'App four') }

    let!(:app_one_signin_permission) { app_one.signin_permission.tap { |s| s.update_attributes(delegatable: true) } }
    let!(:app_two_signin_permission) { app_two.signin_permission.tap { |s| s.update_attributes(delegatable: false) } }
    let!(:app_three_signin_permission) { app_three.signin_permission.tap { |s| s.update_attributes(delegatable: true) } }
    let!(:app_four_signin_permission) { app_four.signin_permission.tap { |s| s.update_attributes(delegatable: false) } }

    context 'for super admins' do
      let(:acting_user) { create(:superadmin_user) }

      it 'includes all applications' do
        expect(resolved_scope).to include(app_one)
        expect(resolved_scope).to include(app_two)
        expect(resolved_scope).to include(app_three)
        expect(resolved_scope).to include(app_four)
      end
    end

    context 'for admins' do
      let(:acting_user) { create(:admin_user) }

      it 'includes all applications' do
        expect(resolved_scope).to include(app_one)
        expect(resolved_scope).to include(app_two)
        expect(resolved_scope).to include(app_three)
        expect(resolved_scope).to include(app_four)
      end
    end

    context 'for super organisation admins' do
      let(:acting_user) { create(:super_org_admin) }

      before do
        acting_user.grant_application_permission(app_one, 'signin')
        acting_user.grant_application_permission(app_two, 'signin')
      end

      it 'includes applications with delegatable signin that the super organisation admin has access to' do
        expect(resolved_scope).to include(app_one)
      end

      it 'does not include applications without delegatable signin that the super organisation admin does has access to' do
        expect(resolved_scope).not_to include(app_two)
      end

      it 'does not include applications that the super organisation admin does not have access to' do
        expect(resolved_scope).not_to include(app_three)
        expect(resolved_scope).not_to include(app_four)
      end
    end

    context 'for organisation admins' do
      let(:acting_user) { create(:organisation_admin) }

      before do
        acting_user.grant_application_permission(app_one, 'signin')
        acting_user.grant_application_permission(app_two, 'signin')
      end

      it 'includes applications with delegatable signin that the organisation admin has access to' do
        expect(resolved_scope).to include(app_one)
      end

      it 'does not include applications without delegatable signin that the organisation admin does has access to' do
        expect(resolved_scope).not_to include(app_two)
      end

      it 'does not include applications that the organisation admin does not have access to' do
        expect(resolved_scope).not_to include(app_three)
        expect(resolved_scope).not_to include(app_four)
      end
    end

    context 'for normal users' do
      let(:acting_user) { create(:user) }

      it 'is empty' do
        expect(resolved_scope).to be_empty
      end
    end
  end
end
